import os
import secrets
from datetime import date, datetime, timezone

from flask import Flask, flash, redirect, render_template, request, url_for
from flask_sqlalchemy import SQLAlchemy
from sqlalchemy import URL

app = Flask(__name__)
app.secret_key = os.getenv("FLASK_SECRET_KEY", "local-development-key")


def build_database_url():
    if os.getenv("DATABASE_URL"):
        return os.environ["DATABASE_URL"]

    if os.getenv("DB_HOST"):
        return URL.create(
            drivername="postgresql+psycopg",
            username=os.getenv("DB_USER"),
            password=os.getenv("DB_PASSWORD"),
            host=os.getenv("DB_HOST"),
            port=int(os.getenv("DB_PORT", "5432")),
            database=os.getenv("DB_NAME", "passbooking"),
        )

    return "sqlite:///bookings.db"


app.config["SQLALCHEMY_DATABASE_URI"] = build_database_url()
app.config["SQLALCHEMY_TRACK_MODIFICATIONS"] = False
db = SQLAlchemy(app)


class Booking(db.Model):
    __tablename__ = "bookings"

    id = db.Column(db.Integer, primary_key=True)
    reference = db.Column(db.String(20), unique=True, nullable=False, index=True)
    full_name = db.Column(db.String(120), nullable=False)
    email = db.Column(db.String(255), nullable=False)
    phone = db.Column(db.String(30), nullable=False)
    pass_type = db.Column(db.String(50), nullable=False)
    travel_date = db.Column(db.Date, nullable=False)
    created_at = db.Column(
        db.DateTime(timezone=True),
        nullable=False,
        default=lambda: datetime.now(timezone.utc),
    )


PASS_TYPES = ["Daily Pass", "Weekly Pass", "Monthly Pass"]


@app.get("/")
def index():
    return render_template("index.html", pass_types=PASS_TYPES)


@app.post("/book")
def create_booking():
    full_name = request.form.get("full_name", "").strip()
    email = request.form.get("email", "").strip().lower()
    phone = request.form.get("phone", "").strip()
    pass_type = request.form.get("pass_type", "").strip()
    travel_date_text = request.form.get("travel_date", "").strip()

    errors = []

    if len(full_name) < 2:
        errors.append("Enter a valid full name.")

    if "@" not in email or "." not in email:
        errors.append("Enter a valid email address.")

    if len(phone) < 7:
        errors.append("Enter a valid phone number.")

    if pass_type not in PASS_TYPES:
        errors.append("Select a valid pass type.")

    try:
        travel_date = date.fromisoformat(travel_date_text)
    except ValueError:
        travel_date = None
        errors.append("Select a valid travel date.")

    if travel_date and travel_date < date.today():
        errors.append("The travel date cannot be in the past.")

    if errors:
        for error in errors:
            flash(error, "error")
        return redirect(url_for("index"))

    booking = Booking(
        reference=f"PB-{secrets.token_hex(4).upper()}",
        full_name=full_name,
        email=email,
        phone=phone,
        pass_type=pass_type,
        travel_date=travel_date,
    )

    try:
        db.session.add(booking)
        db.session.commit()
    except Exception:
        db.session.rollback()
        app.logger.exception("Unable to save booking")
        flash("The booking could not be saved. Please try again.", "error")
        return redirect(url_for("index"))

    return redirect(url_for("booking_success", reference=booking.reference))


@app.get("/success/<reference>")
def booking_success(reference):
    booking = Booking.query.filter_by(reference=reference).first_or_404()
    return render_template("success.html", booking=booking)


@app.get("/bookings")
def list_bookings():
    bookings = Booking.query.order_by(Booking.created_at.desc()).all()
    return render_template("bookings.html", bookings=bookings)


@app.get("/health")
def health():
    return {"status": "ok", "service": "simple-pass-booking"}, 200


with app.app_context():
    db.create_all()


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000, debug=True)

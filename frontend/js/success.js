import { getBooking } from "./api.js";

const params = new URLSearchParams(window.location.search);
const reference = params.get("reference");

if (reference) {
    try {
        const booking = await getBooking(reference);

        document.getElementById("bookingReference").textContent = booking.reference;
        document.getElementById("customerName").textContent = booking.full_name;
        document.getElementById("passType").textContent = booking.pass_type;

        document.getElementById("travelDate").textContent =
            new Date(booking.travel_date).toLocaleDateString();

    } catch (error) {
        console.error(error);
    }
}
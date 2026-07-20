// console.log("bookings.js loaded");

import { getBookings } from "./api.js";

const tbody = document.getElementById("bookingsTableBody");
const bookingCount = document.getElementById("bookingCount");
const emptyState = document.getElementById("emptyState");
const recordsCard = document.querySelector(".records-card");

try {

    const bookings = await getBookings();

    bookingCount.textContent =
        `${bookings.length} stored booking${bookings.length === 1 ? "" : "s"}`;

    if (bookings.length === 0) {
        recordsCard.style.display = "none";
        emptyState.style.display = "block";
    } else {

        bookings.forEach(booking => {

            tbody.insertAdjacentHTML("beforeend", `
                <tr>
                    <td>
                        <span class="reference-cell">${booking.reference}</span>
                    </td>

                    <td>
                        <div class="customer-cell">
                            <span class="avatar">${booking.full_name.charAt(0).toUpperCase()}</span>

                            <div>
                                <strong>${booking.full_name}</strong>
                                <small>Customer</small>
                            </div>
                        </div>
                    </td>

                    <td>
                        <strong>${booking.email}</strong><br>
                        <small>${booking.phone}</small>
                    </td>

                    <td>${booking.pass_type}</td>

                    <td>${new Date(booking.travel_date).toLocaleDateString()}</td>

                    <td>
                        <span class="status-pill">Confirmed</span>
                    </td>
                </tr>
            `);

        });

    }

} catch (error) {
    console.error(error);
}
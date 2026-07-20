import { getPassTypes, createBooking } from "./api.js";

const form = document.getElementById("bookingForm");
const passTypeSelect = document.getElementById("pass_type");
const messageBox = document.getElementById("formMessage");

async function loadPassTypes() {
    try {
        const passTypes = await getPassTypes();

        passTypes.forEach(pass => {
            const option = document.createElement("option");
            option.value = pass;
            option.textContent = pass;
            passTypeSelect.appendChild(option);
        });

    } catch (error) {
        messageBox.textContent = error.message;
    }
}

form.addEventListener("submit", async (event) => {

    event.preventDefault();

    messageBox.textContent = "";

    const booking = {
        full_name: form.full_name.value,
        email: form.email.value,
        phone: form.phone.value,
        pass_type: form.pass_type.value,
        travel_date: form.travel_date.value
    };

    try {

        const response = await createBooking(booking);

        window.location.href =
            `success.html?reference=${response.reference}`;

    } catch (error) {

        messageBox.textContent = error.message;

    }

});

loadPassTypes();
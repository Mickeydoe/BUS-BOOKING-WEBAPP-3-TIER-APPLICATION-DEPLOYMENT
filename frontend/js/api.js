import { API_BASE_URL } from "./config.js";

async function handleResponse(response) {
    const data = await response.json();

    if (!response.ok) {
        throw new Error(data.message || "Request failed.");
    }

    return data;
}

export async function getPassTypes() {
    const response = await fetch(`${API_BASE_URL}/api/pass-types`);
    return handleResponse(response);
}

export async function createBooking(booking) {
    const response = await fetch(`${API_BASE_URL}/api/book`, {
        method: "POST",
        headers: {
            "Content-Type": "application/json"
        },
        body: JSON.stringify(booking)
    });

    return handleResponse(response);
}

export async function getBooking(reference) {
    const response = await fetch(
        `${API_BASE_URL}/api/bookings/${reference}`
    );

    return handleResponse(response);
}

export async function getBookings() {
    const response = await fetch(
        `${API_BASE_URL}/api/bookings`
    );

    return handleResponse(response);
}
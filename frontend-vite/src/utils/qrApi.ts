export async function submitQRRequest(data: any) {

    const response = await fetch("/api/generate/", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(data),
    });


    const result = await response.json();
    if (!response.ok) throw new Error(result.error || "QR generation failed");
    return result.qr_image;
}

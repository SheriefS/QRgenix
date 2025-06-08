import React, { useState } from "react";
import Navbar from "../components/Navbar";
import QRForm from "../components/QRForm";
import QRPreview from "../components/QRPreview";
import Toast from "../components/Toast";

function GenerateQR() {
    const [qrImage, setQrImage] = useState<string | null>(null);
    const [toastMessage, setToastMessage] = useState<string | null>(null);

    return (
        <div >
            <Navbar />
            <div className="min-h-screen bg-gradient-to-br from-purple-700 to-violet-900 text-white p-6">

                <h1 className="text-3xl font-bold mb-4 text-orange-400">Generate QR Code</h1>
                <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                    <QRForm setQrImage={setQrImage} />
                    <QRPreview qrImage={qrImage} setToastMessage={setToastMessage} />
                </div>
                {toastMessage && (
                    <Toast message={toastMessage} onClose={() => setToastMessage(null)} />
                )}
            </div>

        </div>
    );
}

export default GenerateQR
/* src/components/QRPreview.tsx */

import Button from "./Button";

interface QRPreviewProps {
    qrImage: string | null;
    setToastMessage: (msg: string) => void;
}

function QRPreview({ qrImage, setToastMessage }: QRPreviewProps) {

    const canUseClipboard =
        typeof navigator !== "undefined" &&
        typeof window !== "undefined" &&
        !!navigator.clipboard &&
        (window.isSecureContext || window.location.hostname === "localhost");

    const handleDownload = () => {
        if (!qrImage) return;
        const a = document.createElement("a");
        a.href = qrImage;
        a.download = "qr-code.png";
        a.click();

        setToastMessage("📥 Image downloaded!");
    };

    const handleSave = () => {
        console.log("Save clicked");
    };

    const handleCopy = async () => {
        if (!qrImage) return;

        if (!canUseClipboard) {
            setToastMessage('❌ Clipboard not available');
            return;
        }

        try {
            const blob = await fetch(qrImage).then(res => res.blob());

            await navigator.clipboard.write([
                new ClipboardItem({ [blob.type]: blob })
            ]);

            setToastMessage("✅ Image copied to clipboard!");

            console.log("✅ Image copied to clipboard!");
        } catch (err) {
            console.error("❌ Failed to copy image:", err);
            setToastMessage("❌ Failed to copy image");
        }
    };

    if (!qrImage) return (
        <div className="flex flex-col items-center justify-center gap-4">
            <h1 className="text-3xl font-bold text-orange-400">QR Preview</h1>
            <div className="bg-white p-4">
                <img src="https://api.qrserver.com/v1/create-qr-code/?data=https://example.com&size=200x200" alt="QR Preview" />
            </div>
        </div>
    );

    console.log("🔍 QR image updated:", qrImage?.slice(0, 50));

    return (

        <div className="flex flex-col items-center justify-center gap-4">
            <h1 className="text-3xl font-bold text-orange-400">QR Preview</h1>
            <div className="bg-white p-4">
                <img src={qrImage} alt="QR Preview" className="w-48 h-48 object-contain " />
            </div>
            <div className="flex gap-4">
                <Button label="Download" onClick={handleDownload} />
                <Button label="Save" onClick={handleSave} />
                <Button label="Copy" onClick={handleCopy} disabled={!canUseClipboard} />
            </div>
        </div>
    );


}

export default QRPreview
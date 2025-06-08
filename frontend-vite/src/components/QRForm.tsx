/* src/components/QRForm.tsx */
import React, { useState } from 'react';


import Button from './Button';
import ColorPicker from "./ColorPicker";
import Toggle from "./Toggle";
import LogoUpload from "./LogoUpload";
import { submitQRRequest } from "../utils/qrApi";
import { fileToBase64 } from "../utils/fileUtils";

interface QRFormProps {
  setQrImage: (img: string) => void;
}

function QRForm({ setQrImage }: QRFormProps) {

  const [url, setUrl] = useState('');
  const [qrColor, setQrColor] = useState('#000000');
  const [bgColor, setBgColor] = useState('#ffffff');
  const [minify, setMinify] = useState(false);
  const [logoFile, setLogoFile] = useState<File | null>(null);


  const handleLogoChange = (file: File | null, preview: string | null) => {
    setLogoFile(file);
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    console.log("🔁 Submit triggered");

    let logoData: string | null = null;
    if (logoFile) {
      logoData = await fileToBase64(logoFile);
    }

    const payload = {
      url,
      color: qrColor,
      bg_color: bgColor,
      minify,
      logo_data: logoData,  // Later we'll handle this with file uploads
    };

    try {
      const img = await submitQRRequest(payload);
      setQrImage(img);
      console.log("🖼️ setQrImage called in submit handler");
    } catch (err) {
      console.error("❌", err);
    }
  };

  return (
    <form className="flex flex-col gap-4" onSubmit={handleSubmit}>
      <label htmlFor="url-input" className="font-bold">URL:</label>
      <input
        id="url-input"
        type="text"
        value={url}
        onChange={(e) => setUrl(e.target.value)}
        placeholder="Enter your URL here"
        className="w-full p-2 rounded bg-white text-black placeholder-gray-500 outline-none focus:ring-2 focus:ring-orange-400"
      />

      <LogoUpload onLogoChange={handleLogoChange} />

      <Toggle
        label="Shorten URL"
        checked={minify}
        onChange={setMinify}
      />

      <div className="flex items-center gap-6">
        <ColorPicker label="QR Color:" defaultValue="#000000" onChange={setQrColor} />
        <ColorPicker label="Background:" defaultValue="#ffffff" onChange={setBgColor} />
      </div>

      <button type="submit" className="bg-orange-400 px-4 py-2 rounded text-black font-bold hover:bg-orange-500 transition">
        Generate
      </button>
    </form>
  );
}

export default QRForm
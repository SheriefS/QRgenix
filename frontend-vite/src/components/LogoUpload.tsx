// components/LogoUpload.tsx

import React, { useRef, useState } from "react";

import Button from "./Button";

interface LogoUploadProps {
    onLogoChange: (file: File | null, preview: string | null) => void;
}

function LogoUpload({ onLogoChange }: LogoUploadProps) {
    const [fileKey, setFileKey] = useState(Date.now());
    const [preview, setPreview] = useState<string | null>(null);
    const fileInputRef = useRef<HTMLInputElement>(null);

    const handleFileChange = (e: React.ChangeEvent<HTMLInputElement>) => {
        const file = e.target.files?.[0] || null;

        if (file) {
            const reader = new FileReader();
            reader.onloadend = () => {
                const result = reader.result as string;
                setPreview(result);
                onLogoChange(file, result); // this sets logoFile in parent
            };
            reader.readAsDataURL(file);
        }
    };

    const handleClear = () => {
        setPreview(null);
        setFileKey(Date.now()); // triggers input remount
        onLogoChange(null, null); // still necessary so parent clears logoFile
    };

    return (
        <div className="flex flex-col gap-2">
            <label htmlFor="logo-upload" className="font-bold">Logo:</label>
            <input
                id="logo-upload"
                key={fileKey}
                ref={fileInputRef}
                type="file"
                accept="image/*"
                onChange={handleFileChange}
                className="file:mr-4 file:py-2 file:px-4 file:rounded file:border-0 file:bg-orange-400 file:text-white"
            />

            {preview && (
                <>
                    <div className="flex gap-4">
                        <Button label="Clear" onClick={handleClear} type="button" />
                    </div>
                    <div>
                        <p className="text-sm text-gray-300 mb-1">Logo Preview:</p>
                        <img
                            src={preview}
                            alt="Logo preview"
                            className="h-20 w-20 object-contain border border-white rounded"
                        />
                    </div>
                </>
            )}
        </div>
    );
}

export default LogoUpload

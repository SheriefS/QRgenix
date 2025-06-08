/* src/components/Toast.tsx */
import React, { useEffect } from "react";

interface ToastProps {
    message: string;
    onClose: () => void;
}

function Toast({ message, onClose }: ToastProps) {
    useEffect(() => {
        const timer = setTimeout(() => {
            onClose();
        }, 3000); // auto-dismiss after 3s

        return () => clearTimeout(timer);
    }, [onClose]);

    return (
        <div
            role="alert"
            className="fixed bottom-6 right-6 bg-gray-600 text-white px-4 py-2 rounded shadow-lg animate-fade-in">
            {message}
            <button className="ml-2 text-sm underline" onClick={onClose}>Dismiss</button>
        </div>
    );
}

export default Toast;

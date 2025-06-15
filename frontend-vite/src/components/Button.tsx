/* src/components/Button.tsx */

type ButtonProps = {
    label: string;
    onClick: () => void;
    type?: "button" | "submit" | "reset";
    disabled?: boolean;

};

function Button({ label, onClick, type = "button", disabled = false }: ButtonProps) {
    return (
        <button
            type={type}
            onClick={onClick}
            disabled={disabled}
            className="bg-orange-400 px-4 py-2 rounded text-black font-bold hover:bg-orange-500 transition"
        >
            {label}
        </button>
    );
}

export default Button

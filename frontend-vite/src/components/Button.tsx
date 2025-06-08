/* src/components/Button.tsx */

type ButtonProps = {
    label: string;
    onClick: () => void;
    type?: "button" | "submit" | "reset";
};

function Button({ label, onClick, type = "button" }: ButtonProps) {
    return (
        <button
            type={type}
            onClick={onClick}
            className="bg-orange-400 px-4 py-2 rounded text-black font-bold hover:bg-orange-500 transition"
        >
            {label}
        </button>
    );
}

export default Button

/* src/components/Toggle.tsx */

type ToggleProps = {
    label: string;
    checked: boolean;
    onChange: (checked: boolean) => void;
};

function Toggle({ label, checked, onChange }: ToggleProps) {
    return (
        <div className="flex items-center gap-2">
            <span className="text-white font-medium">{label}</span>
            <button
                type="button"
                role="switch"
                aria-checked={checked}
                aria-label={label}
                onClick={() => onChange(!checked)}
                className={`w-12 h-6 flex items-center rounded-full p-1 transition-colors duration-300
          ${checked ? "bg-orange-400" : "bg-gray-400"}`}
            >
                <div
                    className={`bg-white w-4 h-4 rounded-full shadow-md transform transition-transform duration-300
            ${checked ? "translate-x-6" : "translate-x-0"}`}
                />
            </button>
        </div>
    );
}

export default Toggle;
/* src/components/ColorPicker.tsx */

type ColorPickerProps = {
    label: string;
    defaultValue: string;
    onChange?: (color: string) => void;
};

function ColorPicker({ label, defaultValue, onChange }: ColorPickerProps) {

    const id = label.toLowerCase().replace(/\s+/g, "-") + "-color";

    return (
        <div className="flex flex-col items-center">
            <label htmlFor={id} className="font-bold">
                {label}
            </label>
            <input
                id={id}
                type="color"
                className="w-16 h-8 p-0 border-2 border-black"
                defaultValue={defaultValue}
                onChange={(e) => onChange?.(e.target.value)}
            />
        </div>
    );
}

export default ColorPicker;

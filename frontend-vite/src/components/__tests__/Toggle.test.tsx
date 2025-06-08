// src/components/__tests__/Toggle.test.tsx
import { describe, it, expect, vi, beforeEach, test } from 'vitest';
import { render, fireEvent } from "@testing-library/react";
import Toggle from "../Toggle";

test("toggles state when clicked", () => {
    const onChange = vi.fn();
    const { getByRole } = render(<Toggle label="Shorten URL" checked={false} onChange={onChange} />);
    const toggle = getByRole("switch");
    fireEvent.click(toggle);
    expect(onChange).toHaveBeenCalledWith(true);
});

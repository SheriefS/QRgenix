// src/components/__tests__/Button.test.tsx
import { describe, it, expect, vi, beforeEach, test } from 'vitest';
import { render, fireEvent } from "@testing-library/react";
import Button from "../Button";

test("calls onClick when clicked", () => {
    const onClick = vi.fn();
    const { getByText } = render(<Button label="Click Me" onClick={onClick} />);
    fireEvent.click(getByText("Click Me"));
    expect(onClick).toHaveBeenCalled();
});

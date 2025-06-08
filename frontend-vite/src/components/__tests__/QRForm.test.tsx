/// <reference types="vitest" />

import userEvent from "@testing-library/user-event";
import { describe, it, expect, vi, beforeEach, test } from 'vitest';
import { render, screen, fireEvent } from '@testing-library/react';
import QRForm from '../QRForm';
import * as api from '../../utils/qrApi';

test('renders all key input fields and button', () => {
    render(<QRForm setQrImage={() => { }} />);

    expect(screen.getByPlaceholderText(/enter your url/i)).toBeInTheDocument();
    expect(screen.getByLabelText(/logo/i)).toBeInTheDocument();
    expect(screen.getByLabelText(/shorten url/i)).toBeInTheDocument();
    expect(screen.getByLabelText(/QR Color:/i)).toBeInTheDocument();
    expect(screen.getByLabelText(/Background:/i)).toBeInTheDocument();
    expect(screen.getByRole('button', { name: /generate/i })).toBeInTheDocument();
});

//State Update Test (simulate typing)
test('updates URL state on typing', async () => {
    render(<QRForm setQrImage={() => { }} />);
    const input = screen.getByPlaceholderText(/enter your url/i);
    await userEvent.type(input, 'https://example.com');
    expect(input).toHaveValue('https://example.com');
});

// Submit Function is Triggered
test('calls submitQRRequest on form submission', async () => {
    const mockSubmit = vi.spyOn(api, 'submitQRRequest').mockResolvedValue('data:image/png;base64,someImage');
    const mockSetQrImage = vi.fn();

    render(<QRForm setQrImage={mockSetQrImage} />);

    await userEvent.type(screen.getByPlaceholderText(/enter your url/i), 'https://test.dev');
    await userEvent.click(screen.getByRole('button', { name: /generate/i }));

    expect(mockSubmit).toHaveBeenCalled();
    expect(mockSetQrImage).toHaveBeenCalledWith('data:image/png;base64,someImage');

    mockSubmit.mockRestore();
});


// Toggle Functionality
test('toggle changes minify state', async () => {
    render(<QRForm setQrImage={() => { }} />);
    const toggle = screen.getByLabelText(/shorten url/i);

    expect(toggle).not.toBeChecked();
    await userEvent.click(toggle);
    expect(toggle).toBeChecked();
});

// Logo Upload Preview Shows

test('accepts logo file and triggers preview logic', async () => {
    const mockFile = new File(['(⌐□_□)'], 'logo.png', { type: 'image/png' });

    render(<QRForm setQrImage={() => { }} />);
    const input = screen.getByLabelText(/logo/i) as HTMLInputElement;

    await userEvent.upload(input, mockFile);

    expect(input.files?.[0]).toStrictEqual(mockFile);
});




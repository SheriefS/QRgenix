import { describe, it, expect, vi, beforeEach, test } from 'vitest';
import { render, screen, fireEvent, waitFor } from '@testing-library/react';
import QRPreview from '../QRPreview';

// Mock ClipboardItem globally
global.ClipboardItem = function (items: Record<string, Blob>) {
    return items;
} as unknown as typeof ClipboardItem;

// Mock navigator.clipboard
Object.assign(navigator, {
    clipboard: {
        write: vi.fn().mockResolvedValue(undefined)
    }
});


describe('QRPreview', () => {
    const dummyImage =
        'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAUA';

    const mockToast = vi.fn();

    beforeEach(() => {
        mockToast.mockClear();
    });

    it('renders fallback image when no qrImage is provided', () => {
        render(<QRPreview qrImage={null} setToastMessage={mockToast} />);
        const fallbackImg = screen.getByAltText(/qr preview/i) as HTMLImageElement;
        expect(fallbackImg).toBeInTheDocument();
        expect(fallbackImg.src).toMatch(/api\.qrserver\.com/);
    });

    it('renders preview image and buttons when qrImage is present', () => {
        render(<QRPreview qrImage={dummyImage} setToastMessage={mockToast} />);
        expect(screen.getByAltText(/qr preview/i)).toBeInTheDocument();
        expect(screen.getByRole('button', { name: /download/i })).toBeInTheDocument();
        expect(screen.getByRole('button', { name: /copy/i })).toBeInTheDocument();
        expect(screen.getByRole('button', { name: /save/i })).toBeInTheDocument();
    });

    it('copies image to clipboard and shows toast', async () => {
        // Mock Clipboard API
        const writeMock = vi.fn();
        Object.assign(navigator, {
            clipboard: { write: writeMock },
        });

        global.fetch = vi.fn(() =>
            Promise.resolve({
                blob: () => Promise.resolve(new Blob(['mock'], { type: 'image/png' })),
            } as Response)
        );

        render(<QRPreview qrImage={dummyImage} setToastMessage={mockToast} />);
        const copyBtn = screen.getByRole('button', { name: /copy/i });
        fireEvent.click(copyBtn);

        await waitFor(() => {
            expect(mockToast).toHaveBeenCalledWith('✅ Image copied to clipboard!');
        });
    });

    test('downloads image and triggers toast', () => {
        const setToastMessage = vi.fn();
        const qrImage = "data:image/png;base64,somebase64string";

        // ✅ Properly mock createElement just for anchor elements
        const anchorMock = {
            href: "",
            download: "",
            click: vi.fn(),
        };

        // Only override when tagName === "a"
        const originalCreateElement = document.createElement;
        vi.spyOn(document, 'createElement').mockImplementation((tagName: string) => {
            if (tagName === 'a') return anchorMock as unknown as HTMLAnchorElement;
            return originalCreateElement.call(document, tagName);
        });

        render(<QRPreview qrImage={qrImage} setToastMessage={setToastMessage} />);

        const downloadBtn = screen.getByText(/download/i);
        fireEvent.click(downloadBtn);

        expect(anchorMock.click).toHaveBeenCalled();
        expect(setToastMessage).toHaveBeenCalledWith("📥 Image downloaded!");
    });

});

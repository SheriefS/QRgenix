// src/components/Navbar.tsx
import { Link, NavLink } from 'react-router-dom';
import logo from '../assets/QRgenix_logo_Text.png';

export default function Navbar() {
  return (
    <nav className="sticky top-0 z-50 bg-gradient-to-r from-[#555491] to-[#ffa500] text-black px-6 py-4 flex justify-between items-center shadow-lg">
      {/* Logo */}
      <Link to="/" className="text-2xl font-bold hover:opacity-80 transition">
        <img src={logo} alt="QRgenix Logo" className="h-14 w-auto max-w-xs object-contain" />
      </Link>

      {/* Nav Links */}
      <div className="space-x-4 font-semibold">
        <NavLink
          to="/home"
          className={({ isActive }) =>
            isActive ? "underline text-white" : "hover:text-white transition"
          }
        >
          Home
        </NavLink>
        <NavLink
          to="/generate_qr"
          className={({ isActive }) =>
            isActive ? "underline text-white" : "hover:text-white transition"
          }
        >
          Generate QR
        </NavLink>
        <NavLink
          to="/about"
          className={({ isActive }) =>
            isActive ? "underline text-white" : "hover:text-white transition"
          }
        >
          About
        </NavLink>
      </div>
    </nav>
  );
}
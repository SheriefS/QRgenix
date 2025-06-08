
import { Routes, Route } from 'react-router-dom';
import './index.css'
import Home from './pages/Home'
import GenerateQR from './pages/GenerateQR';
import About from './pages/About'

function App() {
  
  return (
      <Routes>
        <Route path='/' element={<Home />} />
        <Route path='/home' element={<Home />} />
        <Route path='/about' element={<About />} />
        <Route path='/generate_qr' element={<GenerateQR />} />
      </Routes>
  );

}

export default App

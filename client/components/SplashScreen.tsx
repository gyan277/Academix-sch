import { useEffect, useState } from "react";

interface SplashScreenProps {
  onFinish: () => void;
}

export default function SplashScreen({ onFinish }: SplashScreenProps) {
  const [fadeOut, setFadeOut] = useState(false);

  useEffect(() => {
    // Start fade out after 2.7 seconds
    const fadeTimer = setTimeout(() => {
      setFadeOut(true);
    }, 2700);

    // Call onFinish after 3 seconds
    const finishTimer = setTimeout(() => {
      onFinish();
    }, 3000);

    return () => {
      clearTimeout(fadeTimer);
      clearTimeout(finishTimer);
    };
  }, [onFinish]);

  return (
    <div
      className={`fixed inset-0 z-50 flex flex-col items-center justify-center bg-gradient-to-br from-gray-50 via-slate-50 to-gray-100 transition-opacity duration-300 ${
        fadeOut ? "opacity-0" : "opacity-100"
      }`}
    >
      {/* Animated background circles */}
      <div className="absolute inset-0 overflow-hidden">
        <div className="absolute top-1/4 left-1/4 w-64 h-64 bg-gray-200 rounded-full mix-blend-multiply filter blur-xl opacity-40 animate-blob"></div>
        <div className="absolute top-1/3 right-1/4 w-64 h-64 bg-slate-200 rounded-full mix-blend-multiply filter blur-xl opacity-40 animate-blob animation-delay-2000"></div>
        <div className="absolute bottom-1/4 left-1/3 w-64 h-64 bg-zinc-200 rounded-full mix-blend-multiply filter blur-xl opacity-40 animate-blob animation-delay-4000"></div>
      </div>

      {/* Main content */}
      <div className="relative flex flex-col items-center space-y-8">
        {/* Logo container with animations */}
        <div className="relative animate-in fade-in zoom-in duration-700">
          {/* Pulsing ring effect */}
          <div className="absolute inset-0 flex items-center justify-center">
            <div className="w-40 h-40 rounded-full bg-gray-300 opacity-15 animate-ping"></div>
          </div>
          <div className="absolute inset-0 flex items-center justify-center animation-delay-1000">
            <div className="w-36 h-36 rounded-full bg-slate-300 opacity-15 animate-ping"></div>
          </div>
          
          {/* Logo with floating animation */}
          <div className="relative animate-float">
            <img
              src="/logo.png"
              alt="Academix Logo"
              className="w-32 h-32 object-contain drop-shadow-2xl"
            />
          </div>
        </div>

        {/* Text with shimmer effect */}
        <div className="relative animate-in fade-in slide-in-from-bottom-4 duration-700 animation-delay-300">
          <h1 className="text-5xl font-bold text-transparent bg-clip-text bg-gradient-to-r from-gray-700 via-slate-700 to-gray-800 tracking-wide animate-shimmer bg-[length:200%_100%]">
            Academix
          </h1>
          
          {/* Subtitle with fade-in */}
          <p className="text-center text-sm text-gray-500 mt-2 animate-in fade-in duration-700 animation-delay-500">
            School Management System
          </p>
        </div>

        {/* Loading dots */}
        <div className="flex space-x-2 animate-in fade-in duration-700 animation-delay-700">
          <div className="w-2 h-2 bg-gray-400 rounded-full animate-bounce"></div>
          <div className="w-2 h-2 bg-slate-400 rounded-full animate-bounce animation-delay-200"></div>
          <div className="w-2 h-2 bg-gray-500 rounded-full animate-bounce animation-delay-400"></div>
        </div>
      </div>
    </div>
  );
}

import React from 'react';

export default function Logo({ className = "text-2xl", white = false }) {
    return (
        <div className={`font-nunito font-bold tracking-tight select-none ${className} ${white ? 'text-white' : 'text-fidelio-black'}`}>
            <span className="text-fidelio-primary">B</span>ackly
        </div>
    );
}

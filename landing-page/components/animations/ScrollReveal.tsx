'use client';

import { useRef, ReactNode } from 'react';
import gsap from 'gsap';
import { ScrollTrigger } from 'gsap/ScrollTrigger';
import { useGSAP } from '@gsap/react';

gsap.registerPlugin(ScrollTrigger);

interface ScrollRevealProps {
  children: ReactNode;
  animation?: 'fade' | 'slide-up' | 'slide-left' | 'slide-right' | 'scale' | 'fade-scale';
  delay?: number;
  duration?: number;
  triggerStart?: string;
  className?: string;
}

export function ScrollReveal({
  children,
  animation = 'fade-scale',
  delay = 0,
  duration = 0.8,
  triggerStart = 'top 80%',
  className = '',
}: ScrollRevealProps) {
  const elementRef = useRef<HTMLDivElement>(null);

  useGSAP(() => {
    if (!elementRef.current) return;

    const animations: Record<string, gsap.TweenVars> = {
      fade: {
        opacity: 0,
      },
      'slide-up': {
        opacity: 0,
        y: 50,
      },
      'slide-left': {
        opacity: 0,
        x: 50,
      },
      'slide-right': {
        opacity: 0,
        x: -50,
      },
      scale: {
        opacity: 0,
        scale: 0.8,
      },
      'fade-scale': {
        opacity: 0,
        scale: 0.95,
        y: 30,
      },
    };

    gsap.from(elementRef.current, {
      ...animations[animation],
      duration,
      delay,
      ease: 'power3.out',
      scrollTrigger: {
        trigger: elementRef.current,
        start: triggerStart,
        toggleActions: 'play none none reverse',
      },
    });
  }, { scope: elementRef });

  return (
    <div ref={elementRef} className={className}>
      {children}
    </div>
  );
}

'use client';

import { useEffect, useRef } from 'react';
import DOMPurify from 'dompurify';
import { cn } from '@/lib/utils';

interface RichContentRendererProps {
  content: string;
  className?: string;
}

export function RichContentRenderer({ content, className }: RichContentRendererProps) {
  const contentRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    if (contentRef.current && typeof window !== 'undefined') {
      // Configure DOMPurify to allow safe HTML elements and attributes
      const clean = DOMPurify.sanitize(content, {
        ALLOWED_TAGS: [
          'p', 'br', 'strong', 'em', 'u', 's', 'a', 'ul', 'ol', 'li',
          'h1', 'h2', 'h3', 'h4', 'h5', 'h6', 'blockquote', 'code', 'pre',
          'img', 'div', 'span', 'table', 'thead', 'tbody', 'tr', 'th', 'td',
          'hr', 'sub', 'sup', 'mark', 'del', 'ins'
        ],
        ALLOWED_ATTR: [
          'href', 'title', 'target', 'rel', 'src', 'alt', 'width', 'height',
          'class', 'id', 'style'
        ],
        ALLOWED_URI_REGEXP: /^(?:(?:(?:f|ht)tps?|mailto|tel|callto|sms|cid|xmpp|data|blob):|[^a-z]|[a-z+.\-]+(?:[^a-z+.\-:]|$))/i,
      });

      contentRef.current.innerHTML = clean;

      // Process all links to open in new tab
      const links = contentRef.current.querySelectorAll('a');
      links.forEach((link) => {
        link.setAttribute('target', '_blank');
        link.setAttribute('rel', 'noopener noreferrer');
      });

      // Process all images to ensure they're responsive
      const images = contentRef.current.querySelectorAll('img');
      images.forEach((img) => {
        img.classList.add('max-w-full', 'h-auto', 'rounded-lg');
      });
    }
  }, [content]);

  return (
    <div
      ref={contentRef}
      className={cn(
        'prose prose-sm max-w-none',
        'prose-headings:text-foreground prose-headings:font-semibold',
        'prose-p:text-muted-foreground prose-p:leading-relaxed',
        'prose-a:text-primary prose-a:no-underline hover:prose-a:underline',
        'prose-strong:text-foreground prose-strong:font-semibold',
        'prose-code:text-foreground prose-code:bg-muted prose-code:px-1 prose-code:py-0.5 prose-code:rounded',
        'prose-pre:bg-muted prose-pre:text-foreground prose-pre:border prose-pre:border-border',
        'prose-img:rounded-lg prose-img:shadow-md prose-img:my-4',
        'prose-blockquote:border-l-primary prose-blockquote:text-muted-foreground',
        'prose-ul:text-muted-foreground prose-ol:text-muted-foreground',
        'prose-li:text-muted-foreground',
        'prose-hr:border-border',
        'prose-table:border prose-table:border-border',
        'prose-th:bg-muted prose-th:text-foreground prose-th:border prose-th:border-border',
        'prose-td:border prose-td:border-border prose-td:text-muted-foreground',
        className
      )}
    />
  );
}

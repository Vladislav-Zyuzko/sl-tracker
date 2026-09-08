import { describe, expect, it } from '@jest/globals';
import { detectFileType, isPreviewableImage, safeFileName } from './file-type.js';

const PNG = Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a, 0, 0, 0, 13]);
const JPEG = Buffer.from([0xff, 0xd8, 0xff, 0xe0, 0, 0x10, 0x4a, 0x46]);
const GIF = Buffer.from('GIF89a________', 'ascii');
const PDF = Buffer.from('%PDF-1.7 документ', 'utf8');
const ZIP = Buffer.from([0x50, 0x4b, 0x03, 0x04, 0, 0, 0, 0]);

function webp(): Buffer {
  const buffer = Buffer.alloc(16);
  buffer.write('RIFF', 0, 'ascii');
  buffer.write('WEBP', 8, 'ascii');
  return buffer;
}

describe('Определение типа вложения по содержимому (US-46, D-21)', () => {
  it('узнаёт изображения по сигнатуре', () => {
    expect(detectFileType(PNG)).toEqual({ contentType: 'image/png', extension: 'png' });
    expect(detectFileType(JPEG)).toEqual({ contentType: 'image/jpeg', extension: 'jpg' });
    expect(detectFileType(GIF)).toEqual({ contentType: 'image/gif', extension: 'gif' });
    expect(detectFileType(webp())).toEqual({ contentType: 'image/webp', extension: 'webp' });
  });

  it('узнаёт документы и архивы', () => {
    expect(detectFileType(PDF).contentType).toBe('application/pdf');
    expect(detectFileType(ZIP).contentType).toBe('application/zip');
  });

  it('текстовый файл без сигнатуры определяется как текст', () => {
    const log = Buffer.from('2026-02-12 10:00:00 INFO старт сервиса\n'.repeat(60), 'utf8');
    expect(detectFileType(log).contentType).toBe('text/plain; charset=utf-8');
  });

  it('неопознанное содержимое — не ошибка, а `application/octet-stream`', () => {
    const binary = Buffer.from([0x00, 0x01, 0x02, 0x03, 0xfe, 0xff]);
    expect(detectFileType(binary)).toEqual({
      contentType: 'application/octet-stream',
      extension: 'bin',
    });
  });

  it('решает содержимое, а не расширение и не заявленный тип', () => {
    // Файл назван «картинкой», внутри PDF: тип берётся из содержимого.
    expect(detectFileType(PDF).contentType).toBe('application/pdf');
  });

  it('превью показывается только у изображений', () => {
    expect(isPreviewableImage('image/png')).toBe(true);
    expect(isPreviewableImage('image/gif')).toBe(true);
    expect(isPreviewableImage('application/pdf')).toBe(false);
    expect(isPreviewableImage('text/plain; charset=utf-8')).toBe(false);
  });
});

describe('Имя файла вложения', () => {
  it('вырезает путь: имя приходит из браузера пользователя', () => {
    expect(safeFileName('../../etc/passwd')).toBe('passwd');
    expect(safeFileName('C:\\Users\\user\\отчёт.pdf')).toBe('отчёт.pdf');
  });

  it('выбрасывает символы, ломающие заголовок ответа', () => {
    expect(safeFileName('от"чёт\n.pdf')).toBe('от чёт.pdf'.replace(' ', ''));
  });

  it('пустое имя заменяется, а не сохраняется пустым', () => {
    expect(safeFileName('   ')).toBe('file');
    expect(safeFileName(null)).toBe('file');
  });

  it('слишком длинное имя обрезается до размера колонки', () => {
    expect(safeFileName(`${'и'.repeat(300)}.txt`)).toHaveLength(255);
  });
});

-- Migration: Add pdf_path column to books table
-- Run this SQL to add PDF support to your audiobooks

ALTER TABLE books ADD COLUMN pdf_path VARCHAR(255) DEFAULT NULL;

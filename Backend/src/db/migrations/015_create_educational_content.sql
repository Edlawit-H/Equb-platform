CREATE TABLE IF NOT EXISTS educational_content (
  content_id   UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  title        VARCHAR(200) NOT NULL,
  description  TEXT,
  content_type VARCHAR(20)  NOT NULL DEFAULT 'article' CHECK (content_type IN ('article', 'video', 'guide', 'infographic')),
  url          TEXT,
  created_at   TIMESTAMP    NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_educational_content_type ON educational_content(content_type);

-- Create storage bucket for hero videos (using your existing bucket)
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'myleapstorage',
  'myleapstorage',
  true,
  52428800, -- 50MB limit
  ARRAY['video/mp4', 'video/webm', 'video/mov', 'video/avi']
) ON CONFLICT (id) DO NOTHING;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Public read access for myleap storage" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated users can upload to myleap storage" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated users can update myleap storage" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated users can delete from myleap storage" ON storage.objects;

-- Create policy to allow public read access
CREATE POLICY "Public read access for myleap storage" ON storage.objects
FOR SELECT USING (bucket_id = 'myleapstorage');

-- Create policy to allow authenticated users to upload
CREATE POLICY "Authenticated users can upload to myleap storage" ON storage.objects
FOR INSERT WITH CHECK (
  bucket_id = 'myleapstorage' 
  AND auth.role() = 'authenticated'
);

-- Create policy to allow authenticated users to update
CREATE POLICY "Authenticated users can update myleap storage" ON storage.objects
FOR UPDATE USING (
  bucket_id = 'myleapstorage' 
  AND auth.role() = 'authenticated'
);

-- Create policy to allow authenticated users to delete
CREATE POLICY "Authenticated users can delete from myleap storage" ON storage.objects
FOR DELETE USING (
  bucket_id = 'myleapstorage' 
  AND auth.role() = 'authenticated'
);

-- Create settings table for hero configuration
CREATE TABLE IF NOT EXISTS hero_settings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  video_url TEXT,
  fallback_image_url TEXT DEFAULT 'https://hebbkx1anhila5yf.public.blob.vercel-storage.com/logomyleap-37GUK91dbp1Doo4vgaDxsr4HMi129U.png',
  video_enabled BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Clear existing settings and insert new ones
DELETE FROM hero_settings;

-- Insert default settings with your video
INSERT INTO hero_settings (video_url, fallback_image_url, video_enabled)
VALUES (
  'myleapvideo.mp4', -- Your uploaded video
  'https://hebbkx1anhila5yf.public.blob.vercel-storage.com/logomyleap-37GUK91dbp1Doo4vgaDxsr4HMi129U.png',
  true
);

-- Create function to get hero settings
CREATE OR REPLACE FUNCTION get_hero_settings()
RETURNS TABLE (
  video_url TEXT,
  fallback_image_url TEXT,
  video_enabled BOOLEAN
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    hs.video_url,
    hs.fallback_image_url,
    hs.video_enabled
  FROM hero_settings hs
  ORDER BY hs.created_at DESC
  LIMIT 1;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant permissions
GRANT EXECUTE ON FUNCTION get_hero_settings() TO anon, authenticated;

-- Enable RLS on hero_settings
ALTER TABLE hero_settings ENABLE ROW LEVEL SECURITY;

-- Create policy for hero_settings
CREATE POLICY "Anyone can read hero settings" ON hero_settings
FOR SELECT USING (true);

CREATE POLICY "Authenticated users can modify hero settings" ON hero_settings
FOR ALL USING (auth.role() = 'authenticated');

-- Show current settings
SELECT 'Hero video storage setup completed successfully!' as message;
SELECT * FROM get_hero_settings();

-- Show simple message about video URL
SELECT 'Your video should be accessible at your Supabase project URL + /storage/v1/object/public/myleapstorage/myleapvideo.mp4' as video_url_info;

-- Verify the file exists in storage
SELECT 
  'Files in myleapstorage bucket:' as info,
  name,
  created_at,
  updated_at
FROM storage.objects 
WHERE bucket_id = 'myleapstorage'
ORDER BY created_at DESC;

-- Show bucket configuration
SELECT 
  'Bucket configuration:' as info,
  id,
  name,
  public,
  file_size_limit
FROM storage.buckets 
WHERE id = 'myleapstorage';

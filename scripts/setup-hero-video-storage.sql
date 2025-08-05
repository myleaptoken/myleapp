-- Create storage bucket for hero videos (using your existing bucket)
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'myleapstorage',
  'myleapstorage',
  true,
  52428800, -- 50MB limit
  ARRAY['video/mp4', 'video/webm', 'video/mov', 'video/avi']
) ON CONFLICT (id) DO NOTHING;

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

-- Insert default settings with your video
INSERT INTO hero_settings (video_url, fallback_image_url, video_enabled)
VALUES (
  'myleapvideo.mp4', -- Your uploaded video
  'https://hebbkx1anhila5yf.public.blob.vercel-storage.com/logomyleap-37GUK91dbp1Doo4vgaDxsr4HMi129U.png',
  true
) ON CONFLICT DO NOTHING;

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

-- Show current settings
SELECT 'Hero settings created successfully!' as message;
SELECT * FROM get_hero_settings();

-- Show the video URL that will be used
SELECT 
  'Video URL will be: ' || 
  COALESCE(current_setting('app.supabase_url', true), 'YOUR_SUPABASE_URL') || 
  '/storage/v1/object/public/myleapstorage/myleapvideo.mp4' as video_url;

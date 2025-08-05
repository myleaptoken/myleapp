-- Make sure the bucket is public
UPDATE storage.buckets 
SET public = true 
WHERE id = 'myleapstorage';

-- Verify bucket is now public
SELECT 
  'Updated bucket configuration:' as info,
  id,
  name,
  public,
  file_size_limit,
  allowed_mime_types
FROM storage.buckets 
WHERE id = 'myleapstorage';

-- Check if your video file exists
SELECT 
  'Video file status:' as info,
  name,
  bucket_id,
  created_at,
  updated_at,
  metadata
FROM storage.objects 
WHERE bucket_id = 'myleapstorage' 
  AND name LIKE '%video%' OR name = 'myleapvideo.mp4'
ORDER BY created_at DESC;

-- Test the hero settings function
SELECT 'Hero settings test:' as info;
SELECT * FROM get_hero_settings();

-- Show the complete video URL that should work
SELECT 
  'Complete video URL:' as info,
  CONCAT(
    'https://', 
    current_setting('app.settings.supabase_url')::text,
    '/storage/v1/object/public/myleapstorage/',
    video_url
  ) as full_video_url
FROM get_hero_settings()
WHERE video_url IS NOT NULL;

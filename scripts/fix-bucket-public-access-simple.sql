-- Fix bucket public access - Simple version
-- This script makes the myleapstorage bucket public and verifies the setup

-- Step 1: Make the bucket public
UPDATE storage.buckets 
SET public = true 
WHERE id = 'myleapstorage';

-- Step 2: Verify bucket configuration
SELECT 
    'Bucket configuration:' as info,
    id,
    name,
    public,
    file_size_limit
FROM storage.buckets 
WHERE id = 'myleapstorage';

-- Step 3: List video files in the bucket
SELECT 
    'Video file found:' as info,
    name,
    bucket_id,
    CASE 
        WHEN name LIKE '%.mp4' OR name LIKE '%.webm' OR name LIKE '%.mov' 
        THEN 'true' 
        ELSE 'false' 
    END as is_video
FROM storage.objects 
WHERE bucket_id = 'myleapstorage' 
AND (name LIKE '%.mp4' OR name LIKE '%.webm' OR name LIKE '%.mov');

-- Step 4: Test the get_hero_settings function
SELECT 
    'Hero settings:' as info,
    video_url,
    video_enabled,
    fallback_image_url
FROM get_hero_settings();

-- Step 5: Show current hero_settings table content
SELECT 
    'Current settings in table:' as info,
    video_url,
    video_enabled,
    fallback_image_url,
    created_at,
    updated_at
FROM hero_settings
ORDER BY updated_at DESC
LIMIT 1;

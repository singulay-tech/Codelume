import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.0.0'

const supabase = createClient(
  Deno.env.get('SUPABASE_URL')!,
  Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
)

serve(async (req) => {
  try {
    const { wallpaper_id } = await req.json()

    const authHeader = req.headers.get('Authorization')
    if (!authHeader) {
      return new Response(
        JSON.stringify({ error: 'Authorization header is required' }),
        { status: 401, headers: { 'Content-Type': 'application/json' } }
      )
    }

    const token = authHeader.replace('Bearer ', '')
    const { data: { user }, error: authError } = await supabase.auth.getUser(token)

    if (authError || !user) {
      return new Response(
        JSON.stringify({ error: 'Invalid authorization token' }),
        { status: 401, headers: { 'Content-Type': 'application/json' } }
      )
    }

    const { data: download, error: createDownloadError } = await supabase
      .from('downloads')
      .insert({
        user_id: user.id,
        wallpaper_id,
        amount: 0,
        service_fee: 0,
        status: 'completed',
        completed_at: new Date().toISOString()
      })
      .select()
      .single()

    if (createDownloadError) {
      return new Response(
        JSON.stringify({ error: 'Failed to create download record' }),
        { status: 500, headers: { 'Content-Type': 'application/json' } }
      )
    }

    const { error: wallpaperError } = await supabase
      .from('wallpapers')
      .update({ download_count: supabase.raw('download_count + 1') })
      .eq('id', wallpaper_id)

    if (wallpaperError) {
      console.error('Error updating download count:', wallpaperError)
    }

    return new Response(JSON.stringify({
      success: true,
      download_id: download.id,
      message: 'Free download granted'
    }), {
      headers: { 'Content-Type': 'application/json' }
    })

  } catch (error) {
    console.error('Error granting free download:', error)
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 500, headers: { 'Content-Type': 'application/json' } }
    )
  }
})
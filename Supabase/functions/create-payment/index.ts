import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import Stripe from 'https://esm.sh/stripe@11.1.0'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.0.0'

const stripe = new Stripe(Deno.env.get('STRIPE_SECRET_KEY')!, {
  apiVersion: '2022-11-15',
})

const supabase = createClient(
  Deno.env.get('SUPABASE_URL')!,
  Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
)

const PAYMENT_ENABLED = Deno.env.get('PAYMENT_ENABLED') === 'true'

serve(async (req) => {
  try {
    if (!PAYMENT_ENABLED) {
      return new Response(
        JSON.stringify({ error: 'Payment system is currently disabled' }),
        { status: 503, headers: { 'Content-Type': 'application/json' } }
      )
    }

    const { wallpaper_id } = await req.json()

    if (!wallpaper_id) {
      return new Response(
        JSON.stringify({ error: 'wallpaper_id is required' }),
        { status: 400, headers: { 'Content-Type': 'application/json' } }
      )
    }

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

    const { data: wallpaper, error: wallpaperError } = await supabase
      .from('wallpapers')
      .select('id, title, price, user_id, is_approved')
      .eq('id', wallpaper_id)
      .single()

    if (wallpaperError || !wallpaper) {
      return new Response(
        JSON.stringify({ error: 'Wallpaper not found' }),
        { status: 404, headers: { 'Content-Type': 'application/json' } }
      )
    }

    if (!wallpaper.is_approved) {
      return new Response(
        JSON.stringify({ error: 'Wallpaper is not approved for purchase' }),
        { status: 403, headers: { 'Content-Type': 'application/json' } }
      )
    }

    if (!wallpaper.price || wallpaper.price <= 0) {
      return new Response(
        JSON.stringify({ error: 'Invalid wallpaper price' }),
        { status: 400, headers: { 'Content-Type': 'application/json' } }
      )
    }

    const amount = wallpaper.price

    const { data: existingDownload, error: downloadError } = await supabase
      .from('downloads')
      .select('id')
      .eq('user_id', user.id)
      .eq('wallpaper_id', wallpaper_id)
      .eq('status', 'completed')
      .single()

    if (existingDownload) {
      return new Response(
        JSON.stringify({ error: 'Already purchased', download_id: existingDownload.id }),
        { status: 400, headers: { 'Content-Type': 'application/json' } }
      )
    }

    const serviceFee = Math.round(amount * 0.1 * 100) / 100
    const totalAmount = Math.round(amount * 100)

    const paymentIntent = await stripe.paymentIntents.create({
      amount: totalAmount,
      currency: 'cny',
      payment_method_types: ['apple_pay'],
      metadata: {
        wallpaper_id,
        user_id: user.id,
        service_fee: serviceFee.toString(),
        wallpaper_user_id: wallpaper.user_id
      },
      automatic_payment_methods: {
        enabled: true
      }
    })

    const { data: download, error: createDownloadError } = await supabase
      .from('downloads')
      .insert({
        user_id: user.id,
        wallpaper_id,
        amount,
        service_fee,
        status: 'pending'
      })
      .select()
      .single()

    if (createDownloadError) {
      return new Response(
        JSON.stringify({ error: 'Failed to create download record' }),
        { status: 500, headers: { 'Content-Type': 'application/json' } }
      )
    }

    const { data: payment, error: createPaymentError } = await supabase
      .from('payments')
      .insert({
        id: paymentIntent.id,
        user_id: user.id,
        download_id: download.id,
        amount,
        currency: 'cny',
        status: 'pending'
      })
      .select()
      .single()

    if (createPaymentError) {
      return new Response(
        JSON.stringify({ error: 'Failed to create payment record' }),
        { status: 500, headers: { 'Content-Type': 'application/json' } }
      )
    }

    return new Response(JSON.stringify({
      client_secret: paymentIntent.client_secret,
      payment_intent_id: paymentIntent.id,
      download_id: download.id,
      amount: totalAmount / 100,
      service_fee: serviceFee
    }), {
      headers: { 'Content-Type': 'application/json' }
    })

  } catch (error) {
    console.error('Error creating payment:', error)
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 500, headers: { 'Content-Type': 'application/json' } }
    )
  }
})
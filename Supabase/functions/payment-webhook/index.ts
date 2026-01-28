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
  if (!PAYMENT_ENABLED) {
    return new Response('Payment system is currently disabled', { status: 503 })
  }

  const signature = req.headers.get('stripe-signature')
  const webhookSecret = Deno.env.get('STRIPE_WEBHOOK_SECRET')

  if (!signature || !webhookSecret) {
    return new Response('Missing signature or webhook secret', { status: 400 })
  }

  const payload = await req.text()

  let event: Stripe.Event

  try {
    event = stripe.webhooks.constructEvent(payload, signature, webhookSecret)
  } catch (err) {
    console.error('Webhook signature verification failed:', err.message)
    return new Response('Invalid signature', { status: 400 })
  }

  console.log(`Received event: ${event.type}`)

  try {
    switch (event.type) {
      case 'payment_intent.succeeded': {
        const paymentIntent = event.data.object as Stripe.PaymentIntent
        await handlePaymentSucceeded(paymentIntent)
        break
      }

      case 'payment_intent.payment_failed': {
        const paymentIntent = event.data.object as Stripe.PaymentIntent
        await handlePaymentFailed(paymentIntent)
        break
      }

      default:
        console.log(`Unhandled event type: ${event.type}`)
    }

    return new Response('OK', { status: 200 })
  } catch (error) {
    console.error('Error processing webhook:', error)
    return new Response('Webhook processing failed', { status: 500 })
  }
})

async function handlePaymentSucceeded(paymentIntent: Stripe.PaymentIntent) {
  const { wallpaper_id, user_id, service_fee } = paymentIntent.metadata

  console.log(`Processing successful payment: ${paymentIntent.id}`)

  const { error: paymentError } = await supabase
    .from('payments')
    .update({ status: 'completed' })
    .eq('id', paymentIntent.id)

  if (paymentError) {
    console.error('Error updating payment status:', paymentError)
    throw paymentError
  }

  const { data: downloadData, error: downloadError } = await supabase
    .from('downloads')
    .select('id')
    .eq('user_id', user_id)
    .eq('wallpaper_id', wallpaper_id)
    .order('created_at', { ascending: false })
    .limit(1)
    .single()

  if (downloadError || !downloadData) {
    console.error('Error finding download record:', downloadError)
    throw downloadError || new Error('Download record not found')
  }

  const { error: updateDownloadError } = await supabase
    .from('downloads')
    .update({
      status: 'completed',
      completed_at: new Date().toISOString()
    })
    .eq('id', downloadData.id)

  if (updateDownloadError) {
    console.error('Error updating download status:', updateDownloadError)
    throw updateDownloadError
  }

  const { error: wallpaperError } = await supabase
    .from('wallpapers')
    .update({ download_count: supabase.raw('download_count + 1') })
    .eq('id', wallpaper_id)

  if (wallpaperError) {
    console.error('Error updating download count:', wallpaperError)
    throw wallpaperError
  }

  console.log(`Payment ${paymentIntent.id} processed successfully`)
}

async function handlePaymentFailed(paymentIntent: Stripe.PaymentIntent) {
  console.log(`Processing failed payment: ${paymentIntent.id}`)

  const { error: paymentError } = await supabase
    .from('payments')
    .update({ status: 'failed' })
    .eq('id', paymentIntent.id)

  if (paymentError) {
    console.error('Error updating payment status:', paymentError)
    throw paymentError
  }

  const { data: downloadData, error: downloadError } = await supabase
    .from('downloads')
    .select('id')
    .eq('user_id', paymentIntent.metadata.user_id)
    .eq('wallpaper_id', paymentIntent.metadata.wallpaper_id)
    .order('created_at', { ascending: false })
    .limit(1)
    .single()

  if (downloadError || !downloadData) {
    console.error('Error finding download record:', downloadError)
    return
  }

  const { error: updateDownloadError } = await supabase
    .from('downloads')
    .update({ status: 'failed' })
    .eq('id', downloadData.id)

  if (updateDownloadError) {
    console.error('Error updating download status:', updateDownloadError)
    throw updateDownloadError
  }

  console.log(`Failed payment ${paymentIntent.id} processed`)
}
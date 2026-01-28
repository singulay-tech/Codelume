import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import Stripe from 'https://esm.sh/stripe@11.1.0'

const stripe = new Stripe(Deno.env.get('STRIPE_SECRET_KEY')!, {
  apiVersion: '2022-11-15',
})

serve(async (req) => {
  try {
    const { validation_url, domain } = await req.json()

    if (!validation_url || !domain) {
      return new Response(
        JSON.stringify({ error: 'validation_url and domain are required' }),
        { status: 400, headers: { 'Content-Type': 'application/json' } }
      )
    }

    const merchantSession = await stripe.terminal.connectionTokens.create({
      validation_url,
      domain
    })

    return new Response(JSON.stringify({
      merchant_session: merchantSession
    }), {
      headers: { 'Content-Type': 'application/json' }
    })

  } catch (error) {
    console.error('Error validating Apple Pay:', error)
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 500, headers: { 'Content-Type': 'application/json' } }
    )
  }
})
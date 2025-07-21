import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface Room {
  nom: string
  superficie: number
  designationId: number
}

interface CreateQuoteRequest {
  userId: string
  rooms: Room[]
}

interface Designation {
  id: number
  surface_par_carton: number
}

interface RoomWithCartons extends Room {
  surface_par_carton: number
  cartons: number
}

serve(async (req) => {
  // Handle CORS preflight requests
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // Initialize Supabase client
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    // Parse request body
    const requestBody: CreateQuoteRequest = await req.json()
    const { userId, rooms } = requestBody

    // Validate input
    if (!userId || !rooms || !Array.isArray(rooms) || rooms.length === 0) {
      return new Response(
        JSON.stringify({ 
          error: 'Missing or invalid userId or rooms array' 
        }),
        { 
          status: 400, 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
        }
      )
    }

    // Validate each room
    for (const room of rooms) {
      if (!room.nom || typeof room.superficie !== 'number' || room.superficie <= 0 || !room.designationId) {
        return new Response(
          JSON.stringify({ 
            error: 'Invalid room data: nom, superficie (>0), and designationId are required' 
          }),
          { 
            status: 400, 
            headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
          }
        )
      }
    }

    // Get unique designation IDs
    const designationIds = [...new Set(rooms.map(room => room.designationId))]

    // Fetch designations data
    const { data: designations, error: designationsError } = await supabaseClient
      .from('designations')
      .select('id, surface_par_carton')
      .in('id', designationIds)

    if (designationsError) {
      throw new Error(`Failed to fetch designations: ${designationsError.message}`)
    }

    if (!designations || designations.length !== designationIds.length) {
      return new Response(
        JSON.stringify({ 
          error: 'One or more designation IDs not found' 
        }),
        { 
          status: 404, 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
        }
      )
    }

    // Create designation lookup map
    const designationMap = new Map<number, Designation>()
    designations.forEach(designation => {
      designationMap.set(designation.id, designation)
    })

    // Calculate cartons for each room
    const roomsWithCartons: RoomWithCartons[] = rooms.map(room => {
      const designation = designationMap.get(room.designationId)!
      const cartons = Math.ceil(room.superficie / designation.surface_par_carton)
      
      return {
        ...room,
        surface_par_carton: designation.surface_par_carton,
        cartons
      }
    })

    // Calculate total cartons
    const totalCartons = roomsWithCartons.reduce((sum, room) => sum + room.cartons, 0)

    // Start transaction: Insert quote and rooms
    const { data: quote, error: quoteError } = await supabaseClient
      .from('quotes')
      .insert({
        user_id: userId,
        total_cartons: totalCartons
      })
      .select('id, user_id, created_at, total_cartons')
      .single()

    if (quoteError) {
      throw new Error(`Failed to create quote: ${quoteError.message}`)
    }

    // Insert rooms
    const roomsData = roomsWithCartons.map(room => ({
      quote_id: quote.id,
      nom: room.nom,
      superficie: room.superficie,
      designation_id: room.designationId,
      surface_par_carton: room.surface_par_carton,
      cartons: room.cartons
    }))

    const { data: insertedRooms, error: roomsError } = await supabaseClient
      .from('rooms')
      .insert(roomsData)
      .select('id, nom, superficie, designation_id, surface_par_carton, cartons')

    if (roomsError) {
      // Rollback: delete the quote if rooms insertion failed
      await supabaseClient
        .from('quotes')
        .delete()
        .eq('id', quote.id)
      
      throw new Error(`Failed to create rooms: ${roomsError.message}`)
    }

    // Return complete quote with rooms
    const response = {
      quote: {
        id: quote.id,
        user_id: quote.user_id,
        created_at: quote.created_at,
        total_cartons: quote.total_cartons,
        rooms: insertedRooms
      }
    }

    return new Response(
      JSON.stringify(response),
      { 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 201
      }
    )

  } catch (error) {
    console.error('Edge Function Error:', error)
    
    return new Response(
      JSON.stringify({ 
        error: error instanceof Error ? error.message : 'Internal server error' 
      }),
      { 
        status: 500, 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
      }
    )
  }
})
export default {
  async fetch(request, env, ctx) {
    const url = new URL(request.url);
    const method = request.method;
    const pathname = url.pathname;

    // Configuration
    const SUPABASE_URL = env.SUPABASE_URL; // https://your-project.supabase.co
    const RATE_LIMIT_NAMESPACE = env.RATE_LIMIT; // KV Namespace
    const CACHE_NAMESPACE = env.CACHE; // KV Namespace
    
    // Headers CORS
    const corsHeaders = {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type, Authorization, apikey',
    };

    // Handle preflight requests
    if (method === 'OPTIONS') {
      return new Response(null, {
        status: 200,
        headers: corsHeaders,
      });
    }

    try {
      // Route: GET /designations - Avec cache TTL 60s
      if (method === 'GET' && pathname.includes('/designations')) {
        return await handleDesignationsCache(request, env, corsHeaders);
      }

      // Route: POST /createQuote - Avec rate limiting 10 req/min
      if (method === 'POST' && pathname.includes('/functions/v1/createQuote')) {
        return await handleCreateQuoteRateLimit(request, env, corsHeaders);
      }

      // Autres requêtes: proxy direct vers Supabase
      return await proxyToSupabase(request, env, corsHeaders);

    } catch (error) {
      return new Response(
        JSON.stringify({ error: `Worker error: ${error.message}` }),
        {
          status: 500,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        }
      );
    }
  },
};

// Gestion cache pour /designations
async function handleDesignationsCache(request, env, corsHeaders) {
  const cacheKey = 'designations';
  const TTL = 60; // 60 secondes

  try {
    // Vérifier le cache KV
    const cachedData = await env.CACHE.get(cacheKey);
    
    if (cachedData) {
      console.log('Cache hit for designations');
      return new Response(cachedData, {
        status: 200,
        headers: {
          ...corsHeaders,
          'Content-Type': 'application/json',
          'X-Cache': 'HIT',
          'Cache-Control': `public, max-age=${TTL}`,
        },
      });
    }

    // Cache miss: fetch depuis Supabase
    console.log('Cache miss for designations, fetching from Supabase');
    const supabaseResponse = await fetch(
      `${env.SUPABASE_URL}/rest/v1/designations?select=*&order=nom`,
      {
        method: 'GET',
        headers: {
          'apikey': env.SUPABASE_ANON_KEY,
          'Authorization': `Bearer ${env.SUPABASE_ANON_KEY}`,
          'Content-Type': 'application/json',
        },
      }
    );

    if (!supabaseResponse.ok) {
      throw new Error(`Supabase error: ${supabaseResponse.status}`);
    }

    const data = await supabaseResponse.text();
    
    // Stocker en cache avec TTL
    await env.CACHE.put(cacheKey, data, { expirationTtl: TTL });
    
    return new Response(data, {
      status: 200,
      headers: {
        ...corsHeaders,
        'Content-Type': 'application/json',
        'X-Cache': 'MISS',
        'Cache-Control': `public, max-age=${TTL}`,
      },
    });

  } catch (error) {
    return new Response(
      JSON.stringify({ error: `Cache error: ${error.message}` }),
      {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      }
    );
  }
}

// Gestion rate limiting pour /createQuote
async function handleCreateQuoteRateLimit(request, env, corsHeaders) {
  const clientIP = request.headers.get('CF-Connecting-IP') || 'unknown';
  const rateLimitKey = `rate_limit:${clientIP}`;
  const windowSeconds = 60; // 1 minute
  const maxRequests = 10;

  try {
    // Vérifier le rate limit
    const currentCount = await env.RATE_LIMIT.get(rateLimitKey);
    const count = currentCount ? parseInt(currentCount) : 0;

    if (count >= maxRequests) {
      return new Response(
        JSON.stringify({ 
          error: 'Rate limit exceeded. Maximum 10 requests per minute.',
          retryAfter: windowSeconds 
        }),
        {
          status: 429,
          headers: {
            ...corsHeaders,
            'Content-Type': 'application/json',
            'X-RateLimit-Limit': maxRequests.toString(),
            'X-RateLimit-Remaining': '0',
            'X-RateLimit-Reset': (Date.now() + windowSeconds * 1000).toString(),
            'Retry-After': windowSeconds.toString(),
          },
        }
      );
    }

    // Incrémenter le compteur
    await env.RATE_LIMIT.put(
      rateLimitKey, 
      (count + 1).toString(), 
      { expirationTtl: windowSeconds }
    );

    // Proxy vers Supabase Edge Function
    const supabaseResponse = await fetch(
      `${env.SUPABASE_URL}/functions/v1/createQuote`,
      {
        method: 'POST',
        headers: {
          'Authorization': request.headers.get('Authorization') || `Bearer ${env.SUPABASE_ANON_KEY}`,
          'apikey': env.SUPABASE_ANON_KEY,
          'Content-Type': 'application/json',
        },
        body: await request.text(),
      }
    );

    const responseBody = await supabaseResponse.text();
    
    return new Response(responseBody, {
      status: supabaseResponse.status,
      headers: {
        ...corsHeaders,
        'Content-Type': 'application/json',
        'X-RateLimit-Limit': maxRequests.toString(),
        'X-RateLimit-Remaining': (maxRequests - count - 1).toString(),
        'X-RateLimit-Reset': (Date.now() + windowSeconds * 1000).toString(),
      },
    });

  } catch (error) {
    return new Response(
      JSON.stringify({ error: `Rate limit error: ${error.message}` }),
      {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      }
    );
  }
}

// Proxy direct vers Supabase pour autres routes
async function proxyToSupabase(request, env, corsHeaders) {
  const url = new URL(request.url);
  
  // Remplacer le domaine par celui de Supabase
  const supabaseUrl = url.pathname + url.search;
  const targetUrl = `${env.SUPABASE_URL}${supabaseUrl}`;

  const supabaseResponse = await fetch(targetUrl, {
    method: request.method,
    headers: {
      ...request.headers,
      'apikey': env.SUPABASE_ANON_KEY,
      'Authorization': request.headers.get('Authorization') || `Bearer ${env.SUPABASE_ANON_KEY}`,
    },
    body: request.method !== 'GET' ? await request.text() : undefined,
  });

  const responseBody = await supabaseResponse.text();
  
  return new Response(responseBody, {
    status: supabaseResponse.status,
    headers: {
      ...corsHeaders,
      'Content-Type': supabaseResponse.headers.get('Content-Type') || 'application/json',
    },
  });
}
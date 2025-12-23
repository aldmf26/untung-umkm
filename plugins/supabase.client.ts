export default defineNuxtPlugin((nuxtApp) => {
  // `useSupabaseClient` is provided by `@nuxtjs/supabase` - provide a `$supabase` alias
  const supabase = useSupabaseClient()
  nuxtApp.provide('supabase', supabase)
})

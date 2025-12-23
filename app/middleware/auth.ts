export default defineNuxtRouteMiddleware(async (to) => {
  const supabase = useSupabaseClient();

  const {
    data: { session },
  } = await supabase.auth.getSession();

  if (!session) {
    return navigateTo({
      path: "/login",
      query: { redirect: to.fullPath },
    });
  }
});

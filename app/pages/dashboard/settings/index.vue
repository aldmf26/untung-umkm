<script setup lang="ts">
import * as z from "zod";
import type { FormError, FormSubmitEvent } from "@nuxt/ui";
import UDashboardLayout from "~/layouts/dashboard.vue";

definePageMeta({
  middleware: "auth",
  layout: "dashboard",
});
const passwordSchema = z.object({
  current: z.string().min(6, "Must be at least 6 characters"),
  new: z.string().min(6, "Must be at least 6 characters"),
});

type PasswordSchema = z.output<typeof passwordSchema>;

const password = reactive<Partial<PasswordSchema>>({
  current: undefined,
  new: undefined,
});

const supabase = useSupabaseClient();
const user = useSupabaseUser();
const toast = useToast();

const loading = ref(false);

const validate = (state: Partial<PasswordSchema>): FormError[] => {
  const errors: FormError[] = [];
  if (state.current && state.new && state.current === state.new) {
    errors.push({ name: "new", message: "Passwords must be different" });
  }
  return errors;
};

async function onSubmit(event: FormSubmitEvent<PasswordSchema>) {
  loading.value = true;
  try {
    const email = (user.value as any)?.email;
    if (!email) throw new Error("Email tidak tersedia");

    // Re-authenticate with current password
    const { error: signInError } = await supabase.auth.signInWithPassword({
      email,
      password: event.data.current,
    });
    if (signInError) throw signInError;

    // Update password
    const { error: updateError } = await supabase.auth.updateUser({
      password: event.data.new,
    });
    if (updateError) throw updateError;

    toast.add({ title: "Password diperbarui", color: "success" });

    // Clear form
    password.current = undefined;
    password.new = undefined;
  } catch (err: any) {
    toast.add({
      title: "Gagal",
      description: err.message || String(err),
      color: "error",
    });
  } finally {
    loading.value = false;
  }
}

useHead({
  title: "Ubah Password",
});
</script>

<template>
  <UPageCard
    title="Password"
    description="Confirm your current password before setting a new one."
    variant="subtle"
  >
    <UForm
      :schema="passwordSchema"
      :state="password"
      :validate="validate"
      @submit="onSubmit"
      class="flex flex-col gap-4 max-w-xs"
    >
      <UFormField name="current">
        <UInput
          v-model="password.current"
          type="password"
          placeholder="Current password"
          class="w-full"
        />
      </UFormField>

      <UFormField name="new">
        <UInput
          v-model="password.new"
          type="password"
          placeholder="New password"
          class="w-full"
        />
      </UFormField>

      <UButton
        :loading="loading"
        :disabled="loading || !password.current || !password.new"
        label="Update"
        class="w-fit"
        type="submit"
      />
    </UForm>
  </UPageCard>

  <UPageCard
    title="Account"
    description="No longer want to use our service? You can delete your account here. This action is not reversible. All information related to this account will be deleted permanently."
    class="bg-linear-to-tl from-error/10 from-5% to-default"
  >
    <template #footer>
      <UButton label="Delete account" color="error" />
    </template>
  </UPageCard>
</template>

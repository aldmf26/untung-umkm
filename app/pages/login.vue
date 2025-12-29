<script setup lang="ts">
const { signIn } = useAuth();
const router = useRouter();
const route = useRoute();

const show = ref(false);
const email = ref("");
const password = ref("");
const loading = ref(false);
const errorMessage = ref("");

// Ambil redirect path dari query atau default ke pengukuran-badan
const redirectTo = computed(
  () => (route.query.redirect as string) || "/dashboard"
);

const handleLogin = async () => {
  loading.value = true;
  errorMessage.value = "";

  const { error } = await signIn(email.value, password.value);

  loading.value = false;

  if (error) {
    errorMessage.value = error.message;
    return;
  }

  await router.push(redirectTo.value);
};

useHead({
  title: "Login",
});
</script>

<template>
  <UCard variant="subtle" class="w-full max-w-md shadow-lg">
    <template #header>
      <div class="text-center space-y-3">
        <h2
          class="text-2xl sm:text-3xl font-bold from-pink-500 to-purple-600 bg-clip-text"
        >
          Login Laporku
        </h2>
      </div>
    </template>

    <form @submit.prevent="handleLogin" class="space-y-4">
      <!-- Alert Error -->
      <UAlert
        v-if="errorMessage"
        color="error"
        variant="soft"
        :title="errorMessage"
        icon="i-lucide-circle-x"
        :close-button="{ icon: 'i-lucide-x', color: 'red', variant: 'link' }"
        @close="errorMessage = ''"
      />

      <!-- Email Input -->
      <div class="space-y-2">
        <label
          class="block text-sm font-semibold text-gray-700 dark:text-gray-300"
        >
          📧 Email
        </label>
        <UInput
          v-model="email"
          type="email"
          placeholder="contoh@email.com"
          class="w-full"
          size="lg"
          :disabled="loading"
          required
        />
      </div>

      <!-- Password Input -->
      <div class="space-y-2">
        <label
          class="block text-sm font-semibold text-gray-700 dark:text-gray-300"
        >
          🔒 Password
        </label>
        <UInput
          v-model="password"
          type="password"
          placeholder="••••••••"
          size="lg"
          class="w-full"
          :type="show ? 'text' : 'password'"
          :disabled="loading"
          required
        />
      </div>

      <!-- Login Button -->
      <UButton
        type="submit"
        block
        size="lg"
        :loading="loading"
        :disabled="loading"
        class="from-pink-500 to-purple-600 hover:from-pink-600 hover:to-purple-700"
      >
        <span v-if="!loading">Masuk</span>
        <span v-else>Memproses...</span>
      </UButton>
    </form>
  </UCard>
</template>

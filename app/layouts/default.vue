<template>
  <UHeader>
    <template #title>
      <Logo class="h-6 w-auto" />
      <h1>UMKM Dashboard</h1>
    </template>

    <template #right>
      <UColorModeButton />

      <UTooltip text="Open on Instagram" :kbds="['meta', 'G']">
        <UButton
          color="neutral"
          variant="ghost"
          to="https://instagram.com/@aldiiimf"
          target="_blank"
          icon="i-simple-icons-instagram"
          aria-label="Instagram"
        />
      </UTooltip>
    </template>
  </UHeader>
  <UContainer
    class="sm:mt-8 flex flex-col items-center justify-center w-full px-3 sm:px-4"
  >
    <template v-if="$route.name !== 'index'">
      <div class="flex justify-center">
        <UButton
          color="primary"
          class="cursor-pointer mb-3"
          variant="soft"
          icon="i-heroicons-arrow-long-left"
          @click="$router.back()"
        >
          Kembali
        </UButton>
      </div>
    </template>
    <slot />
  </UContainer>
</template>

<template>
  <UHeader>
    <template #title>
      <AppLogo />
    </template>

    <template #right>
      <UColorModeButton />
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

<script setup lang="ts">
const props = withDefaults(
  defineProps<{
    count?: number;
    ids?: string[];
  }>(),
  {
    count: 0,
    ids: undefined,
  }
);

const open = ref(false);
const emit = defineEmits<{
  (e: "confirmed"): void;
  (e: "deleted", ids?: string[]): void;
}>();

const loading = ref(false);
const toast = useToast();

async function onSubmit() {
  // If ids passed, perform deletion here
  if (props.ids && props.ids.length) {
    loading.value = true;
    const supabase = useSupabaseClient();
    const { error } = await supabase
      .from("umkm_profiles")
      .delete()
      .in("id", props.ids);
    loading.value = false;

    if (error) {
      toast.add({
        title: "Gagal menghapus",
        description: error.message,
        color: "error",
      });
      return;
    }

    toast.add({
      title: "UMKM dihapus",
      description: `${props.ids.length} item dihapus`,
      color: "success",
    });
    emit("deleted", props.ids);
    open.value = false;
    return;
  }

  // fallback: let parent handle deletion (bulk delete)
  emit("confirmed");
  open.value = false;
}
</script>

<template>
  <UModal
    v-model:open="open"
    :title="`Delete ${
      props.count ?? (props.ids ? props.ids.length : 1)
    } customer${
      (props.count ?? (props.ids ? props.ids.length : 1)) > 1 ? 's' : ''
    }`"
    :description="`Are you sure, this action cannot be undone.`"
  >
    <slot />

    <template #body>
      <div class="flex justify-end gap-2">
        <UButton
          label="Cancel"
          color="neutral"
          variant="subtle"
          @click="open = false"
        />
        <UButton
          label="Delete"
          color="error"
          variant="solid"
          :loading="loading"
          :disabled="loading"
          @click="onSubmit"
        />
      </div>
    </template>
  </UModal>
</template>

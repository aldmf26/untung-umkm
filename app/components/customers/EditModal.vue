<script setup lang="ts">
import * as z from 'zod'
import type { FormSubmitEvent } from '@nuxt/ui'

const props = withDefaults(
  defineProps<{
    item?: Record<string, any>
  }>(),
  {
    item: undefined,
  }
)

const emit = defineEmits<{
  (e: 'updated', payload?: any): void
}>()

const schema = z.object({
  nama_usaha: z.string().min(3),
  nama_pemilik: z.string().min(3),
  no_wa: z.string().min(10).regex(/^[0-9]+$/),
  tanggal_join: z.string().min(1),
  status: z.enum(['active', 'trial', 'inactive']),
  catatan: z.string().optional(),
})

type Schema = z.output<typeof schema>

const open = ref(false)
const toast = useToast()

const state = reactive<Partial<Schema>>({})

watch(
  () => props.item,
  (v) => {
    if (v) {
      state.nama_usaha = v.nama_usaha
      state.nama_pemilik = v.nama_pemilik
      state.no_wa = v.no_wa
      state.tanggal_join = v.tanggal_join
      state.status = v.status
      state.catatan = v.catatan
    }
  },
  { immediate: true }
)

async function onSubmit(event: FormSubmitEvent<Schema>) {
  if (!props.item?.id) return

  const supabase = useSupabaseClient()
  const { data: updated, error } = await supabase
    .from('umkm_profiles')
    .update([
      {
        nama_usaha: event.data.nama_usaha,
        nama_pemilik: event.data.nama_pemilik,
        no_wa: event.data.no_wa,
        tanggal_join: event.data.tanggal_join,
        status: event.data.status,
        catatan: event.data.catatan || null,
      },
    ])
    .eq('id', props.item.id)
    .select()
    .single()

  if (error) {
    toast.add({ title: 'Gagal update', description: error.message, color: 'error' })
    return
  }

  toast.add({ title: 'UMKM diperbarui', description: updated.nama_usaha, color: 'success' })
  open.value = false
  emit('updated', updated)
}
</script>

<template>
  <UModal v-model:open="open" title="Edit UMKM" description="Perbarui data UMKM">
    <slot>
      <UButton icon="i-heroicons-pencil-square" size="xs" variant="ghost" />
    </slot>

    <template #body>
      <UForm :schema="schema" :state="state" @submit="onSubmit" class="space-y-4">
        <UFormField name="nama_usaha" label="Nama Usaha" required>
          <UInput v-model="state.nama_usaha" size="lg" />
        </UFormField>

        <UFormField name="nama_pemilik" label="Nama Pemilik" required>
          <UInput v-model="state.nama_pemilik" size="lg" />
        </UFormField>

        <UFormField name="no_wa" label="No. WhatsApp" required>
          <UInput v-model="state.no_wa" size="lg" />
        </UFormField>

        <UFormField name="tanggal_join" label="Tanggal Join" required>
          <UInput v-model="state.tanggal_join" type="date" size="lg" />
        </UFormField>

        <UFormField name="status" label="Status" required>
          <USelect v-model="state.status" :items="[
            { label: 'Active', value: 'active' },
            { label: 'Trial', value: 'trial' },
            { label: 'Inactive', value: 'inactive' }
          ]" />
        </UFormField>

        <UFormField name="catatan" label="Catatan (Opsional)">
          <UTextarea v-model="state.catatan" rows="3" />
        </UFormField>

        <div class="flex justify-end gap-2">
          <UButton label="Batal" color="neutral" variant="subtle" @click="open=false" />
          <UButton label="Simpan" color="success" type="submit" />
        </div>
      </UForm>
    </template>
  </UModal>
</template>
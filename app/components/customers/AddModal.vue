<script setup lang="ts">
import * as z from "zod";
import type { FormSubmitEvent } from "@nuxt/ui";

const schema = z.object({
  nama_usaha: z.string().min(3, "Nama usaha minimal 3 karakter"),
  nama_pemilik: z.string().min(3, "Nama pemilik minimal 3 karakter"),
  no_wa: z
    .string()
    .min(10, "Nomor WhatsApp minimal 10 digit")
    .regex(/^[0-9]+$/, "Hanya boleh angka")
    .refine((val) => val.startsWith("08"), "Nomor harus diawali 08"),
  tanggal_join: z.string().min(1, "Tanggal join wajib diisi"),
  status: z.enum(["active", "trial", "inactive"], {
    required_error: "Status wajib dipilih",
  }),
  catatan: z.string().optional(),
});

const open = ref(false);
const emit = defineEmits<{
  (e: "saved", payload?: any): void;
}>();

type Schema = z.output<typeof schema>;

const state = reactive<Partial<Schema>>({
  nama_usaha: undefined,
  nama_pemilik: undefined,
  no_wa: undefined,
  tanggal_join: undefined,
  status: "trial", // Default status untuk UMKM baru
  catatan: undefined,
});

const statusOptions = [
  { label: "Active (Berbayar)", value: "active" },
  { label: "Trial (Gratis)", value: "trial" },
  { label: "Inactive (Berhenti)", value: "inactive" },
];

const toast = useToast();

async function onSubmit(event: FormSubmitEvent<Schema>) {
  const supabase = useSupabaseClient();

  const {
    data: { session },
  } = await supabase.auth.getSession();

  if (!session?.user) {
    throw new Error("User belum login");
  }

  const { data: inserted, error } = await supabase
    .from("umkm_profiles")
    .insert([
      {
        nama_usaha: event.data.nama_usaha,
        nama_pemilik: event.data.nama_pemilik,
        no_wa: event.data.no_wa,
        tanggal_join: event.data.tanggal_join,
        status: event.data.status,
        catatan: event.data.catatan || null,
      },
    ])
    .select()
    .single();

  if (error) {
    toast.add({
      title: "Gagal menambahkan UMKM",
      description: error.message,
      color: "error",
    });
    return;
  }

  toast.add({
    title: "UMKM Berhasil Ditambahkan!",
    description: `${inserted.nama_usaha} telah ditambahkan ke daftar klien`,
    color: "success",
    icon: "i-heroicons-check-circle",
  });

  // Reset form
  state.nama_usaha = undefined;
  state.nama_pemilik = undefined;
  state.no_wa = undefined;
  state.tanggal_join = undefined;
  state.status = "trial";
  state.catatan = undefined;

  open.value = false;

  // Notify parent to refresh
  emit("saved", inserted);
}

// Set default tanggal join ke hari ini
onMounted(() => {
  const today = new Date().toISOString().split("T")[0];
  state.tanggal_join = today;
});
</script>

<template>
  <UModal
    v-model:open="open"
    title="Tambah UMKM Baru"
    description="Tambahkan klien UMKM baru ke database"
    :ui="{ body: 'h-screen  md:m-auto md:p-4 md:px-6' }"
  >
    <UButton label="Tambah UMKM" icon="i-heroicons-plus" color="success" />

    <template #body>
      <UForm
        :schema="schema"
        :state="state"
        class="space-y-4 md:space-y-0 md:grid md:grid-cols-1 md:gap-4"
        @submit="onSubmit"
      >
        <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
          <!-- Nama Usaha -->
          <UFormField
            label="Nama Usaha"
            name="nama_usaha"
            required
            class="md:col-span-2"
          >
            <UInput
              v-model="state.nama_usaha"
              placeholder="Warung Berkah, Laundry Express, dll"
              icon="i-heroicons-building-storefront"
              size="lg"
              class="md:w-full"
            />
          </UFormField>

          <!-- Nama Pemilik -->
          <UFormField label="Nama Pemilik" name="nama_pemilik" required>
            <UInput
              v-model="state.nama_pemilik"
              placeholder="Ibu Siti, Pak Budi, dll"
              icon="i-heroicons-user"
              size="lg"
              class="md:w-full"
            />
          </UFormField>

          <!-- No WhatsApp -->
          <UFormField
            label="No Wa"
            name="no_wa"
            required
            hint="Format: 08xxxxxxxxxx"
          >
            <UInput
              v-model="state.no_wa"
              placeholder="081234567890"
              icon="i-simple-icons-whatsapp"
              size="lg"
              type="tel"
              class="md:w-full"
            />
          </UFormField>

          <!-- Tanggal Join -->
          <UFormField label="Tanggal Join" name="tanggal_join" required>
            <UInput
              v-model="state.tanggal_join"
              type="date"
              icon="i-heroicons-calendar"
              size="lg"
              class="md:w-full"
            />
          </UFormField>

          <!-- Status -->
          <UFormField label="Status" name="status" required>
            <USelect
              v-model="state.status"
              :items="statusOptions"
              size="lg"
              placeholder="Pilih status"
              class="md:w-full"
            />
          </UFormField>

          <!-- Catatan (Optional) -->
          <UFormField
            label="Catatan (Opsional)"
            name="catatan"
            hint="Informasi tambahan tentang klien"
            class="md:col-span-2"
          >
            <UTextarea
              v-model="state.catatan"
              placeholder="Contoh: Referensi dari Pak Budi, sudah pernah konsultasi, dll"
              :rows="3"
              class="md:w-full"
            />
          </UFormField>
        </div>

        <!-- Info Box -->
        <UAlert
          color="info"
          variant="soft"
          icon="i-heroicons-information-circle"
          title="Tips"
          description="Status 'Trial' untuk minggu pertama gratis. Ubah ke 'Active' setelah klien konfirmasi langganan berbayar."
          class="md:mx-auto md:p-4"
        />

        <!-- Action Buttons -->
        <div class="flex justify-end gap-2 pt-4">
          <UButton
            label="Batal"
            color="neutral"
            variant="subtle"
            @click="open = false"
          />
          <UButton
            label="Simpan"
            color="success"
            icon="i-heroicons-check"
            type="submit"
          />
        </div>
      </UForm>
    </template>
  </UModal>
</template>

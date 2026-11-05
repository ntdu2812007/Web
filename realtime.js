// realtime.js – Helper for Supabase Realtime integration
// This module loads initial data and sets up realtime listeners for the main tables.

import { createClient } from 'https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2/dist/esm/index.js';

const SUPABASE_URL = "https://fiuyvbxamddiivzjvdio.supabase.co";
const SUPABASE_ANON_KEY = "sb_publishable_Q13khcwikoAPQhpGZGomMw_mcU3bb6r";

export const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY);
window.realtime = { supabase, loadInitialData, subscribeRealtime };


/** Load initial data for orders, staff, withdraw_requests and transactions */
export async function loadInitialData() {
  const [{ data: orders }, { data: staff }, { data: withdraw }, { data: transactions }] = await Promise.all([
    supabase.from('orders').select('*').order('created_at', { ascending: false }),
    supabase.from('staff').select('*'),
    supabase.from('withdraw_requests').select('*'),
    supabase.from('transactions').select('*'),
  ]);
  return { orders: orders ?? [], staff: staff ?? [], withdraw: withdraw ?? [], transactions: transactions ?? [] };
}

/** Subscribe to realtime changes for the main tables.
 *  callbacks: { onOrder, onStaff, onWithdraw, onTransaction }
 *  Each callback receives (eventType, newRecord, oldRecord).
 */
export function subscribeRealtime(callbacks = {}) {
  // Helper to bind a table to a channel
  const bind = (table, cb) => {
    supabase
      .channel(`public:${table}`)
      .on('postgres_changes', { event: '*', schema: 'public', table }, payload => {
        const { eventType, new: newRec, old: oldRec } = payload;
        cb?.(eventType, newRec, oldRec);
      })
      .subscribe(status => {
        console.log(`Realtime channel for ${table} – status:`, status);
      });
  };

  if (callbacks.onOrder) bind('orders', callbacks.onOrder);
  if (callbacks.onStaff) bind('staff', callbacks.onStaff);
  if (callbacks.onWithdraw) bind('withdraw_requests', callbacks.onWithdraw);
  if (callbacks.onTransaction) bind('transactions', callbacks.onTransaction);
}

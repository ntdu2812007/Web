// realtime.js – Helper for Supabase Broadcast notifications.

(() => {
const SUPABASE_URL = "https://fiuyvbxamddiivzjvdio.supabase.co";
const SUPABASE_ANON_KEY = "sb_publishable_Q13khcwikoAPQhpGZGomMw_mcU3bb6r";

if (!window.supabase?.createClient) {
  throw new Error('Supabase JS client failed to load.');
}

const supabase = window.supabase.createClient(SUPABASE_URL, SUPABASE_ANON_KEY);


/** Subscribe to table-change signals; callbacks should reload protected data via RPC. */
function subscribeRealtime(callbacks = {}) {
  const callbacksByTable = {
    orders: callbacks.onOrder,
    staff: callbacks.onStaff,
    withdraw_requests: callbacks.onWithdraw,
    transactions: callbacks.onTransaction,
  };

  return supabase
    .channel('oms-data-changes')
    .on('broadcast', { event: 'data_changed' }, message => {
      const callback = callbacksByTable[message.payload?.table];
      callback?.('CHANGE', { table: message.payload.table }, null);
    })
    .subscribe(status => {
      console.log('OMS Realtime channel status:', status);
    });
}

window.realtime = { supabase, subscribeRealtime };
})();

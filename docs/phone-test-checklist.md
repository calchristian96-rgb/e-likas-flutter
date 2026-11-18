# Phone test checklist: E-LIKAS 0.3.2+7

For testing on a real phone against the backend at df031fe. Each line is
one thing to try and what you should see. Run the event items in order;
the others can go in any order.

## Events (barangay official)

Start with no event at all (on the web: close every event).

- [ ] Register family shows "No open event yet. CSWDO opens an event when
      a threat is announced." There is no form and no Next.
- [ ] On the web, open an event in **Monitoring**. Pull to refresh Home:
      the event line says "Event: <name>" with a blue **Monitoring** chip.
- [ ] Register family works: the four steps, Review says "Saves to:
      <event>", Save.
- [ ] Once it is sent, Home shows the event as **Active** (amber), without
      reopening the app (the first check-in makes it Active on the server).
- [ ] On the web, open a second event. Home shows **Change** next to the
      event. Change lists "Open events" and "Closed events (read-only)".
- [ ] Choose the other event: "Now working on …". On the web, the same
      user's top bar shows the same event.
- [ ] Choose a closed event: Register family says the event is closed and
      read-only, with nothing to save.
- [ ] Airplane mode, then Change: "Changing the event needs a connection."

## Barangay official

- [ ] Register family, step 3: choose **Private house**. Next stays off
      until the host's name and a purok or address are filled in.
- [ ] Review shows "Private house, with <host>". Save, then sync.
- [ ] Home, **Private houses**: the family is listed with its host and
      place. Tap it: the sheet shows "Private house, with <host>".
- [ ] A family added on the web's Private houses card with ages only
      shows "Details pending".
- [ ] Final count: submit. The dialog shows families in centers and in
      private houses, the checks, "After this, new evacuees are marked as
      late entries.", and **Review first** / **Submit**.
- [ ] After CSWDO validates it, the card says "Validated: N families,
      report as of <time>".
- [ ] Register one more family and sync. The validated figures stay the
      same; a "1 late entry" note appears, and Home's To do says "1 late
      entry, not yet in your final count".
- [ ] The barangay under a preemptive or forced order (set by CSWDO): Home
      and Barangay status show "… ordered by <who> at <time>, recorded by
      <name>". Only Normal, Watch and Flooding reported can be chosen.
- [ ] A full center: on its EC Board, **Ask another barangay's center**.
      Only your barangay's families can be ticked.
- [ ] The center list shows "Room for N", "about N km" for a center that
      is not on the map, and "Capacity unknown". Send needs a reason and a
      confirmation naming the families, persons and both centers.
- [ ] Transfers (Home): the request is **Pending** and the families are
      still at their center.
- [ ] As the receiving barangay's official: the bell shows a notification.
      Tapping it opens Transfers. The request shows only each family's
      head and number of members.
- [ ] Decline needs a reason of at least 3 characters. The sender gets a
      notification and sees **Declined** with the reason.
- [ ] Accept moves the families: they now appear at the receiving
      center, and the sender sees **Accepted**.
- [ ] Leave a request unanswered for 30 minutes: it shows **Escalated to
      CSWD**, and it can still be answered.
- [ ] Airplane mode on Transfers: no Accept or Decline, and the screen says
      it needs a connection. Ask another barangay's center: Send stays off.
- [ ] A center with an estimated capacity shows "48 / 112 est."; one with
      no capacity shows "48 / – (capacity unknown)", no percentage, and
      never Full.

## CSWDO

- [ ] Home: families in private houses, "N late entries pending", and "N
      transfer requests waiting" (tap: Transfers).
- [ ] Transfers lists every request, with Accept and Decline on pending
      ones; the answer shows "(CSWD)".
- [ ] A seeded demo request (no requester) says "Asked by <sending
      barangay>".
- [ ] Barangays → a barangay → Forced evacuation: "Record a forced
      evacuation order for <barangay> in <event>?". Record order stays off
      until you choose who ordered it (City Mayor, CDRRMO, or Someone else
      with a name). The time can be earlier today, never in the future.
- [ ] The barangay page then shows the order line. Airplane mode: the
      order is refused and nothing is queued.
- [ ] A barangay with no official account: **Submit for this barangay**,
      confirm, then it is waiting for validation. A barangay with an
      official says its official submits.
- [ ] A barangay → tap a center → **Move** on a family: the reason is
      required, the confirmation names both centers, and the family moves.
      Offline, Move stays off.
- [ ] Barangay page centers: "est." with a tooltip (2025 peak or median),
      and "(capacity unknown)".

## Resident (signed out)

- [ ] Nearest center and center details: "112 (estimated)" for an
      estimate, "capacity unknown" with no percentage for none.

## Administrator

- [ ] Signing in still shows "Use the web".

// page_nav — a face's navigation (open the Link cell, a friend's cell, make a cell the main one): the page's own verbs, `Page_<verb>`
//  (Ghost/M/RadioPage.g, the /Radio page, spec/AtheoryArrive_todo.md §5), where it has them — else Sounditron’s, on / (until / mounts /Radio).
//    Those lived in the Sounditron Book, a Story that watched the radio start; the page is their home.
export function page_nav(H: any, verb: string, ...args: any[]): any {
    // the /Radio verbs only where there IS a /Radio page: RadioPage.g's ghost is loaded on / too, and there its Page_* found no page and
    //  did nothing (2026-11-12, the Yay cell's "open its Heist" dead on /)
    let page = null
    try { page = H?.Page_w?.() ?? null } catch {}
    const f = (page ? H?.['Page_' + verb] : null) ?? H?.['Sounditron_' + verb] ?? H?.['Page_' + verb]
    return typeof f === 'function' ? f.apply(H, args) : undefined
}

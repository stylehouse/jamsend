// page_nav — a face's navigation (open the Link cell, a friend's cell, make a cell the main one): the page's own verbs, `Page_<verb>`
//  (Ghost/M/RadioPage.g, the /Radio page, spec/AtheoryArrive_todo.md §5), where it has them — else Sounditron’s, on / (until / mounts /Radio).
//    Those lived in the Sounditron Book, a Story that watched the radio start; the page is their home.
export function page_nav(H: any, verb: string, ...args: any[]): any {
    const f = H?.['Page_' + verb] ?? H?.['Sounditron_' + verb]
    return typeof f === 'function' ? f.apply(H, args) : undefined
}

// Feasibility proof: does the machine boot in node and do ghosts deposit?
import { test, expect } from 'vitest'
import { mount } from 'svelte'
import { House } from '../src/lib/O/Housing.svelte'
import Ghost from '../src/lib/O/Ghost.svelte'

test('new House constructs with runes alive', () => {
    const H: any = new House({ name: 'Mundo' })
    expect(H.name).toBe('Mundo')
    expect(typeof H.i_elvisto).toBe('function')
    console.log('[boot] House ok; started=', H.started, ' may_begin?', typeof H.may_begin)
})

test('ghosts mount and deposit methods onto H', async () => {
    const H: any = new House({ name: 'Mundo' })
    mount(Ghost, { target: document.body, props: { H } })
    await new Promise(r => setTimeout(r, 400))
    console.log('[boot] after mount: story_drive?', typeof H.story_drive,
                ' snap_H?', typeof H.snap_H, ' Story?', typeof H.Story,
                ' ghosts keys=', H.ghosts ? Object.keys(H.ghosts).length : '(none)')
    expect(typeof H.story_drive).toBe('function')
})

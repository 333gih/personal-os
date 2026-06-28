package com.personalos.mobile.ui.features

import com.personalos.mobile.data.models.PosCvBlock
import com.personalos.mobile.data.models.PosCvBlockOverrides
import com.personalos.mobile.data.models.PosCvConstraints
import com.personalos.mobile.data.models.PosCvDocument
import com.personalos.mobile.data.models.PosCvTemplate
import com.personalos.mobile.ui.work.parseTechLine
import java.util.UUID

/** Client-side fallback when API templates have empty blocks (mirrors backend DocumentToBlocks). */
object CvDocumentBlocks {
    fun build(doc: PosCvDocument): List<PosCvBlock> {
        val blocks = mutableListOf<PosCvBlock>()
        var order = 0

        fun add(block: PosCvBlock) {
            blocks += block.copy(order = order++)
        }

        val summaryText = when {
            doc.summary.isNotBlank() && doc.headline.isNotBlank() && !doc.summary.contains(doc.headline) ->
                "${doc.headline}\n${doc.summary}"
            doc.summary.isNotBlank() -> doc.summary
            else -> doc.headline
        }
        if (summaryText.isNotBlank()) {
            add(PosCvBlock(id = "summary", type = "summary", content = summaryText))
        }

        doc.contact?.let { contact ->
            val parts = buildList {
                listOfNotNull(contact.email, contact.phone, contact.location)
                    .map { it.trim() }
                    .filter { it.isNotEmpty() }
                    .forEach { add(it) }
                if (!contact.linkedin.isNullOrBlank()) add("LinkedIn")
                if (!contact.github.isNullOrBlank()) add("GitHub")
            }
            if (parts.isNotEmpty()) {
                add(
                    PosCvBlock(
                        id = "contact",
                        type = "contact",
                        content = parts.joinToString(" · "),
                        overrides = PosCvBlockOverrides(
                            email = contact.email,
                            phone = contact.phone,
                            location = contact.location,
                            linkedin = contact.linkedin,
                            github = contact.github,
                        ),
                    ),
                )
            }
        }

        doc.skillGroups?.takeIf { it.isNotEmpty() }?.let { groups ->
            val overrides = doc.primaryStack?.takeIf { it.isNotEmpty() }?.let {
                PosCvBlockOverrides(skillItems = it)
            }
            add(PosCvBlock(id = "skills", type = "skills", skillGroups = groups, overrides = overrides))
        }

        doc.achievements.orEmpty().forEachIndexed { i, item ->
            add(PosCvBlock(id = "achievement-$i", type = "achievements", content = item.content))
        }

        doc.education.orEmpty().forEachIndexed { i, item ->
            var text = item.school
            item.degree?.takeIf { it.isNotBlank() }?.let { text += " · $it" }
            item.period?.takeIf { it.isNotBlank() }?.let { text += " ($it)" }
            item.content?.takeIf { it.isNotBlank() }?.let { text += "\n$it" }
            add(PosCvBlock(id = "education-$i", type = "education", content = text))
        }

        doc.certificates.orEmpty().forEachIndexed { i, item ->
            val text = listOfNotNull(item.title, item.issuer).filter { it.isNotBlank() }.joinToString(" · ")
            add(PosCvBlock(id = "cert-$i", type = "certificates", content = text))
        }

        doc.experience.orEmpty().forEach { item ->
            val id = item.id ?: UUID.randomUUID().toString()
            add(
                PosCvBlock(
                    id = id,
                    type = "experience",
                    sourceEntityId = item.id,
                    content = item.content,
                    overrides = PosCvBlockOverrides(title = item.title, company = item.company, period = item.period),
                ),
            )
        }

        doc.projects.orEmpty().forEach { item ->
            val id = item.id ?: UUID.randomUUID().toString()
            val (stack, cleaned) = parseTechLine(item.content)
            add(
                PosCvBlock(
                    id = id,
                    type = "project",
                    sourceEntityId = item.id,
                    content = cleaned,
                    overrides = PosCvBlockOverrides(
                        title = item.title,
                        company = item.company,
                        period = item.period,
                        highlightStack = stack.takeIf { it.isNotEmpty() },
                    ),
                ),
            )
        }

        return blocks
    }

    fun bootstrapDefaultTemplate(assembled: com.personalos.mobile.data.models.PosAssembledCv): PosCvTemplate? {
        val blocks = build(assembled.document)
        if (blocks.isEmpty()) return null
        return PosCvTemplate(
            id = assembled.documentId.orEmpty().ifBlank { UUID.randomUUID().toString() },
            name = "Professional CV (1 page)",
            isDefault = true,
            isSystem = true,
            constraints = PosCvConstraints(maxPages = 1, maxExperience = 4, maxProjects = 8),
            blocks = blocks,
        )
    }
}
